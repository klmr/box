#' Register S3 methods
#'
#' \code{register_S3_method} makes an S3 method for a given generic and class
#' known inside a module.
#'
#' @param name the name of the generic as a character string
#' @param class the class name
#' @param method the method to register
#'
#' @details Methods for generics defined in the same module do not need to be
#' registered explicitly, and indeed \emph{should not} be registered. However,
#' if the user wants to add a method for a known generic (defined outside the
#' module, e.g. \code{\link{print}}), then this needs to be made known
#' explicitly.
#'
#' @note \strong{Do not} call \code{\link[base]{registerS3method}} inside a
#' module. Only use \code{register_S3_method}. This is important for the
#' module’s own book-keeping.
#' @examples
#' \dontrun{
#' # In module mymod/a:
#' print.my_class = function (x) {
#'     message(sprintf('My class with field %s\n', x$field))
#'     invisible(x)
#' }
#'
#' xyz::register_S3_method('print', 'my_class', print.my_class)
#'
#' # Globally:
#' xyz::use(mymod/a)
#' obj = structure(list(field = 42), class = 'my_class')
#' obj # calls `print.my_class`, with output "My class with field 42"
#' }
#' @export
register_S3_method = function (name, class, method) {
    module = environment(method)
    attr(module, 'S3') = c(attr(module, 'S3'), paste(name, class, sep = '.'))
    registerS3method(name, class, method, module)
}

#' Internal S3 infrastructure helpers
#'
#' The following are internal S3 infrastructure helper functions.
#'
#' \code{is_S3_user_generic} checks whether a function given by name is a
#' user-defined generic. A user-defined generic is any function which, at some
#' point, calls \code{UseMethod}.
#'
#' \code{make_S3_methods_known} finds and registers S3 methods inside a module.
#' @param function_name function name as character string
#' @param envir the environment this function is invoked from
#' @keywords internal
#' @name s3
is_S3_user_generic = function (function_name, envir = parent.frame()) {
    is_S3 = function (b) {
        if (length(b) == 0L) FALSE
        else if (is.function(b)) b = body(b)
        else if (is.call(b)) {
            is_s3_dispatch = is.name(b[[1L]]) && b[[1L]] == 'UseMethod'
            is_s3_dispatch || is_S3(as.list(b)[-1L])
        } else is.recursive(b) && (is_S3(b[[1L]]) || is_S3(b[-1L]))
    }

    ! bindingIsActive(function_name, envir) &&
        is_S3(body(get(function_name, envir = envir, mode = 'function')))
}

#' @param module the module object for which to register S3 methods
#' @rdname s3
make_S3_methods_known = function (module) {
    # S3 methods are found by first finding all generics, and then searching
    # function names with the generic’s name as a prefix. This may however
    # fail for cases where a found name actually corresponds to a method for a
    # different, “known” generic with a dot in its name (an example of this is
    # `se.contrast`). We therefore test whether a method was already
    # registered manually via `register_S3_method` before registering it
    # automatically here. To avoid such ambiguities it is highly recommended
    # not to use dots in function and class names. Use underscores instead.

    functions = lsf(module)
    generics = Filter(function (f) is_S3_user_generic(f, module), functions)

    find_methods = function (generic)
        grep(sprintf('^%s\\.[^.]', generic), functions, value = TRUE)

    methods = map(find_methods, generics)

    register_method = function (name, generic) {
        # Ensure we don’t register functions which have already been
        # registered explicitly. This guards against ambiguous cases.
        if (name %in% attr(module, 'S3')) return()

        # + 1 for dot, + 1 for position after that.
        class = substr(name, nchar(generic) + 2L, nchar(name))
        registerS3method(generic, class, module[[name]], module)
    }

    register_methods = function (methods, generic_name)
        map(register_method, methods, list(generic_name))

    map(register_methods, methods, generics)
    invisible()
}

#' Return a list of function names in an environment
#'
#' @param envir the environment to search in
#' @keywords internal
lsf = function (envir) {
    names(which(eapply(envir, class, all.names = TRUE) == 'function'))
}

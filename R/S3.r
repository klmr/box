#' Register an S3 method for a given generic and class.
#'
#' @param name the name of the generic as a character string
#' @param class the class name
#' @param method the method to register
#'
#' @details Methods for generics defined in the same module do not need to be
#' registered explicitly, and indeed \emph{should not} be registered. However,
#' if the user wants to add a method for a known generic (e.g.
#' \code{\link{print}}), then this needs to be made known explicitly.
#'
#' @note \strong{Do not} call \code{\link{registerS3method}} inside a module.
#' Use \code{register_S3_method} instead – this is important for the module’s
#' own book-keeping.
#' @examples
#' \dontrun{
#' # In module a:
#' print.my_class = function (x) {
#'     cat(sprintf('My class with field %s\n', x$field))
#'     invisible(x)
#' }
#'
#' register_S3_method('print', 'my_class', print.my_class)
#'
#' # Globally:
#' a = import('a')
#' obj = structure(list(field = 42), class = 'my_class')
#' obj # calls `print`, with output "My class with field 42"
#' }
#' @export
register_S3_method = function (name, class, method) {
    module = environment(method)
    attr(module, 'S3') = c(attr(module, 'S3'), paste(name, class, sep = '.'))
    registerS3method(name, class, method, module)
}

#' Check whether a function given by name is a user-defined generic
#'
#' A user-defined generic is any function which, at some point, calls
# \code{UseMethod}.
#' @param function_name function name as character string
#' @param envir the environment this function is invoked from
is_S3_user_generic = function (function_name, envir = parent.frame()) {
    is_S3 = function (b) {
        if (length(b) == 0)
            return(FALSE)
        if (is.call(b)) {
            if (b[[1]] == 'UseMethod')
                return(TRUE)
            return(is_S3(as.list(b)[-1]))
        }
        is.recursive(b) && (is_S3(b[[1]]) || is_S3(b[-1]))
    }

    is_S3(body(get(function_name, envir = envir, mode = 'function')))
}

#' Return a list of functions in an environment
#'
#' @param envir the environment to search in
lsf = function (envir)
    Filter(function (n) exists(n, envir, mode = 'function', inherits = FALSE),
           ls(envir))

#' Find and register S3 methods inside a module
#'
#' @param module the module object for which to register S3 methods
make_S3_methods_known = function (module) {
    # S3 methods are found by first finding all generics, and then searching
    # function names with the generic’s name as a prefix. This may however
    # fail for cases where a found name actually corresponds to a method for a
    # different, “known” generic with a dot in its name (an example of this is
    # `se.contrast`). We therefore test whether a method was already
    # registered manually via `register_S3_method` before registering it
    # automatically here. To avoid such ambiguities it is highly recommended
    # not to use dots in function and class names. Use underscores instead.

    # First step: find generics defined in module

    functions = lsf(module)
    generics = functions[vapply(functions, is_S3_user_generic, logical(1),
                                envir = module)]

    # Second step: register known methods for those generics

    find_methods = function (generic)
        grep(sprintf('^%s\\.[^.]', generic), functions, value = TRUE)

    register_method = function (name, generic) {
        # Ensure we don’t register functions which have already been
        # registered explicitly. This guards against ambiguous cases.
        if (name %in% attr(module, 'S3'))
            return()

        # + 1 for dot, + 1 for position after that.
        class = substr(name, nchar(generic) + 2, nchar(name))
        method = get(name, envir = module, mode = 'function')
        registerS3method(generic, class, method, module)
    }

    register_methods = function (name)
        if (length(methods[[name]]) > 0)
            Map(register_method, methods[[name]], name)

    methods = sapply(generics, find_methods, simplify = FALSE)
    Map(register_methods, names(methods))
    invisible()
}

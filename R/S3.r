#' Register S3 methods
#'
#' \code{box::register_S3_method} makes an S3 method for a given generic and
#' class known inside a module.
#'
#' @usage \special{box::register_S3_method(name, class, method)}
#' @param name the name of the generic as a character string.
#' @param class the class name.
#' @param method the method to register.
#' @return \code{box::register_S3_method} is called for its side effect.
#'
#' @details Methods for generics defined in the same module do not need to be
#' registered explicitly, and indeed \emph{should not} be registered. However,
#' if the user wants to add a method for a known generic (defined outside the
#' module, e.g. \code{\link{print}}), then this needs to be made known
#' explicitly.
#'
#' See the vignette at \code{vignette('box', 'box')} for more information about
#' defining S3 methods inside modules.
#'
#' @note \strong{Do not} call \code{\link[base]{registerS3method}} inside a
#' module. Only use \code{box::register_S3_method}. This is important for the
#' module’s own book-keeping.
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
#' @param function_name function name as character string.
#' @param envir the environment this function is invoked from.
#' @return \code{is_S3_user_generic} returns \code{TRUE} if the specified
#' function is a user-defined S3 generic, \code{FALSE} otherwise.
#' @keywords internal
#' @name s3
is_S3_user_generic = function (function_name, envir = parent.frame()) {
    ! bindingIsActive(function_name, envir) &&
        is_S3(body(get(function_name, envir = envir, mode = 'function')))
}

is_S3 = function (expr) {
    if (length(expr) == 0L) {
        FALSE
    } else if (is.function(expr)) {
        FALSE
    } else if (is.call(expr)) {
        fun = expr[[1L]]
        if (is.name(fun)) {
            # NB: this is relying purely on static analysis. We do not test
            # whether these calls actually refer to the expected base R
            # functions since that would require evaluating the function body in
            # the general case (namely, the function body itself could redefine
            # them).
            if (identical(fun, quote(UseMethod))) return(TRUE)

            # Make sure nested function definitions are *not* getting
            # traversed: `UseMethod` inside a nested function does not make
            # the containing function a generic.
            if (identical(fun, quote(`function`))) return(FALSE)

            # Without `as.list`, missing arguments in call expressions cause
            # missing values in our code. Rather than handle these as speciak
            # cases, we use `as.list` to flatten those into empty expressions.
            Recall(as.list(expr)[-1L])
        } else {
            Recall(fun) || Recall(as.list(expr)[-1L])
        }
    } else if (is.recursive(expr)) {
        Recall(expr[[1L]]) || Recall(expr[-1L])
    } else {
        FALSE
    }
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
#' @param envir the environment to search in.
#' @return \code{lsf} returns a vector of function names in the given environment.
#' @keywords internal
lsf = function (envir) {
    # We cannot use `eapply` here since that will try to evaluate active
    # bindings starting with R 4.1. ‘box’ uses active bindings to for delayed
    # cyclic loading, and these should not be evaluated at this point.
    is_function = function (name) {
        ! bindingIsActive(name, envir) &&
            ! is.null(get0(name, envir, inherits = FALSE, mode = 'function'))
    }
    Filter(is_function, names(envir))
}

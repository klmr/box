#' Throw informative error messages
#'
#' Helpers to generate readable and informative error messages for package
#' users.
#' @param \dots arguments to be passed to \code{fmt}
#' @param call the calling context from which the error is raised
#' @param subclass an optional subclass name for the error condition to be
#' raised
#'
#' @details
#' For \code{rethrow}, the \code{call} argument overrides the rethrown error’s
#' own stored call.
#' @keywords internal
throw = function (..., call = sys.call(sys.parent()), subclass = NULL) {
    message = fmt(..., envir = parent.frame())
    stop(box_error(message, call = call, subclass = subclass))
}

#' @param error an object of class \code{c("error", "condition")} to rethrow
#' @rdname throw
rethrow = function (error, call = sys.call(sys.parent())) {
    if (inherits(error, 'box_error')) {
        # R calls all exit handlers during stack unwind after internally setting
        # the stack traceback. We use this fact to override the traceback with a
        # more useful version that shows the actual calls causing the error,
        # instead of the detour via the `rethrow` logic.
        on.exit({
            # In non-interactive sessions, `.Traceback` might not be created.
            if (exists('.Traceback', .BaseNamespaceEnv)) {
                # In all versions of R currently supported, `tryCatch` inserts 4
                # calls into the call stack, which we excise here.
                tb = error$traceback
                start = Position(function (x) identical(x[[1L]], quote(rethrow_on_error)), tb)
                tb = tb[- seq(start + 1L, start + 4L)]
                if (getRversion() < '4.0.0') {
                    # Prior to R 4.0.0, `.Traceback` contains deparsed calls.
                    tb = map(deparse1, tb)
                }
                if (getRversion() >= '4.1.0') box_unlock_binding('.Traceback', .BaseNamespaceEnv)
                .BaseNamespaceEnv$.Traceback = tb
                if (getRversion() >= '4.1.0') lockBinding('.Traceback', .BaseNamespaceEnv)
            }
        })
    }
    message = conditionMessage(error)
    subclass = setdiff(class(error), box_error_class)
    stop(box_error(message, call = call, subclass = subclass))
}

#' @param expr an expression to evaluate inside \code{tryCatch}
#' @return If it does not throw an error, \code{rethrow_on_error} returns the
#' value of evaluating \code{expr}.
#' @rdname throw
rethrow_on_error = function (expr, call = sys.call(sys.parent())) {
    tryCatch(expr, error = function (error) rethrow(error, call))
}

expect = function (condition, ..., call = sys.call(sys.parent()), subclass = NULL) {
    if (condition) return()
    message = fmt(..., envir = parent.frame())
    stop(box_error(message, call = call, subclass = subclass))
}

box_error_class = c('box_error', 'error', 'condition')

#' @param message the error message
#' @return \code{box_error} returns a new \sQuote{box} error condition object
#' with a given message and call, and optionally a given subclass type.
#' @rdname throw
box_error = function (message, call = NULL, subclass = NULL) {
    class = c(subclass, box_error_class)
    # Store real traceback, in case this is being called from inside
    # `rethrow_on_error`, which overrides the stack trace.
    traceback = sys.calls()
    traceback = traceback[seq_len(length(traceback) - 2L)]
    structure(list(message = message, call = call, traceback = traceback), class = class)
}

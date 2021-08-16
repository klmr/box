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
    throw(
        '{msg}\n(inside {calls})',
        msg = conditionMessage(error),
        calls = paste(dQuote(deparse(conditionCall(error))), collapse = '\n'),
        call = call,
        subclass = setdiff(class(error), box_error_class)
    )
}

#' @param expr an expression to evaluate inside \code{tryCatch}
#' @return If it does not throw an error, \code{rethrow_on_error} returns the
#' value of evaluating \code{expr}.
#' @rdname throw
rethrow_on_error = function (expr, call = sys.call(sys.parent())) {
    tryCatch(expr, error = function (error) rethrow(error, call))
}

box_error_class = c('box_error', 'error', 'condition')

#' @param message the error message
#' @return \code{box_error} returns a new \sQuote{box} error condition object
#' with a given message and call, and optionally a given subclass type.
#' @rdname throw
box_error = function (message, call = NULL, subclass = NULL) {
    class = c(subclass, box_error_class)
    structure(list(message = message, call = call), class = class)
}

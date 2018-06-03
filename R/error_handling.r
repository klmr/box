#' Pretty-print error call to be informative for the user.
#'
#' @param error an object of class \code{c("error", "condition")} to rethrow
#' @param call the calling context to rethrow the error from, overwriting the
#' error’s current call object
#' @keywords internal
rethrow = function (error, call = sys.call(sys.parent())) {
    message = sprintf(
        '%s\n(inside %s)',
        conditionMessage(error), dQuote(deparse(conditionCall(error)))
    )
    stop(simpleError(message, call))
}

#' @param expr an expression to evaluate inside \code{tryCatch}
#' @return If it does not throw an error, \code{rethrow_on_error} returns the
#' value of evaluating \code{expr}.
#' @rdname rethrow
rethrow_on_error = function (expr, call = sys.call(sys.parent())) {
    tryCatch(expr, error = function (error) rethrow(error, call))
}

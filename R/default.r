#' Retrieve a value or a default
#'
#' \code{a \%||\% b} returns \code{a} unless it is empty, in which case
#' \code{b} is returned.
#' @param a the value to return if non-empty
#' @param b default value
#' @return \code{a \%||\% b} returns \code{a}, unless it is \code{NULL}, empty,
#' \code{FALSE} or \code{""}; in which case \code{b} is returned.
#' @name default
#' @keywords internal
`%||%` = function (a, b) {
    is_false = function (a) is.logical(a) && ! isTRUE(a)
    is_empty = function (a) is.character(a) && ! nzchar(a)
    if (is.null(a) || length(a) == 0L || is_false(a) || is_empty(a)) {
        b
    } else {
        a
    }
}

#' \code{lhs \%|\% rhs} is a vectorized version.
#' @param lhs vector with potentially missing values, or \code{NULL}
#' @param rhs vector with default values, same length as \code{lhs} unless that
#'  is \code{NULL}
#' @return \code{lhs \%|\% rhs} returns a vector of the same length as
#' \code{rhs} with all missing values in \code{lhs} replaced by the
#' corresponding values in \code{rhs}.
#' @rdname default
#' @keywords internal
`%|%` = function (lhs, rhs) {
    if (is.null(lhs)) {
        rhs
    } else {
        mapply(`%||%`, lhs, rhs, USE.NAMES = FALSE)
    }
}

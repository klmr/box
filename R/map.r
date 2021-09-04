#' Apply function to elements in list
#'
#' \code{map} applies a function to lists of arguments, similar to \code{Map} in
#' base R, with the argument \code{USE.NAMES} set to \code{FALSE}.
#' \code{flatmap} performs a recursive map: the return type is always a vector
#' of some type given by the \code{.default}, and if the return value of calling
#' \code{.f} is a vector, it is flattened into the enclosing vector (see
#' \sQuote{Examples}).
#' \code{transpose} is a special \code{map} application that concatenates its
#' inputs to compute a transposed list.
#' @param .f an n-ary function where n is the number of further arguments given
#' @param \dots lists of arguments to map over in parallel
#' @param .default the default value returned by \code{flatmap} for an empty
#' input
#' @return \code{map} returns a (potentially nested) list of values resulting
#' from applying \code{.f} to the arguments.
#' @section Examples:
#' \preformatted{
#' flatmap_chr(identity, NULL)
#' # character(0)
#'
#' flatmap_chr(identity, c('a', 'b'))
#' # [1] "a" "b"
#'
#' flatmap_chr(identity, list(c('a', 'b'), 'c'))
#' # [1] "a" "b" "c"
#'
#' transpose(1 : 2, 3 : 4)
#' # [[1]]
#' # [1] 1 3
#' #
#' # [[2]]
#' # [1] 2 4
#' }
#' @keywords internal
map = function (.f, ...) {
    if (length(..1) == 0L) list() else Map(.f, ..., USE.NAMES = FALSE)
}

#' @return \code{flatmap} returns a vector with type given by \code{.default},
#' or \code{.default}, if the input is empty.
#' @rdname map
flatmap = function (.f, ..., .default) {
    Reduce(c, map(.f, ...), .default)
}

#' @rdname map
flatmap_chr = function (.f, ...) {
    flatmap(.f, ..., .default = character(0L))
}

#' @rdname map
vmap = function (.f, .x, ..., .default) {
    # FIXME: Find a more efficient implementation.
    fun_value = eval(call(class(.default), 1L))
    vapply(X = .x, FUN = .f, FUN.VALUE = fun_value, ..., USE.NAMES = FALSE)
}

#' @rdname map
map_int = function (.f, ...) {
    vmap(.f = .f, ..., .default = integer(0L))
}

#' @rdname map
map_lgl = function (.f, ...) {
    vmap(.f = .f, ..., .default = logical(0L))
}

#' @rdname map
map_chr = function (.f, ...) {
    vmap(.f = .f, ..., .default = character(0L))
}

#' @return \code{transpose} returns a list of the element-wise concatenated
#' input vectors; that is, a \dQuote{transposed list} of those elements.
#' @rdname map
transpose = function (...) {
    map(c, ...)
}

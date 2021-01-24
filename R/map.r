#' Apply function to elements in list
#'
#' \code{map} applies a function to lists of arguments, similar to \code{Map} in
#' base R, with the argument \code{USE.NAMES} set to \code{FALSE}.
#' \code{flatmap} performs a recursive map: the return type is always a vector
#' of some type given by the \code{.default}, and if the return value of calling
#' \code{.f} is a vector, it is flattened into the enclosing vector (see
#' examples).
#' @param .f An n-ary function where n is the number of further arguments given.
#' @param ... Lists of arguments to map over in parallel.
#' @param .default The default value returned by flatmap for an empty input.
#' @return \code{map} returns a (potentially nested) list of values resulting
#' from applying \code{.f} to the arguments. \code{flatmap} returns a vector
#' with type given by \code{.default}, or \code{.default}, if the input is
#' empty.
#' @keywords internal
#' @examples
#' \dontrun{
#' flatmap_chr(identity, NULL)
#' # character(0)
#' flatmap_chr(identity, c('a', 'b'))
#' # [1] "a" "b"
#' flatmap_chr(identity, list(c('a', 'b'), 'c'))
#' # [1] "a" "b" "c"
#' }
map = function (.f, ...) {
    if (length(..1) == 0L) list() else Map(.f, ..., USE.NAMES = FALSE)
}

#' @rdname map
flatmap = function (.f, ..., .default) {
    Reduce(c, map(.f, ...), .default)
}

#' @rdname map
flatmap_chr = function (.f, ...) {
    flatmap(.f, ..., .default = character(0L))
}

vmap = function (.f, .x, ..., .default) {
    # FIXME: Find a more efficient implementation.
    fun_value = eval(call(class(.default), 1L))
    vapply(X = .x, FUN = .f, FUN.VALUE = fun_value, ..., USE.NAMES = FALSE)
}

map_int = function (.f, ...) {
    vmap(.f = .f, ..., .default = integer(0L))
}

map_lgl = function (.f, ...) {
    vmap(.f = .f, ..., .default = logical(0L))
}

map_chr = function (.f, ...) {
    vmap(.f = .f, ..., .default = character(0L))
}

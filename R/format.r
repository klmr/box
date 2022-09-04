#' String formatting helpers
#'
#' Interpolate expressions in a string
#' @param \dots one or more unnamed character string arguments, followed
#' optionally by named arguments
#' @param x an object to convert
#' @param a a character vector of length \code{n}
#' @param b a character vector of length \code{n - 1}
#' @return \code{fmt(\dots)} concatenates any unnamed arguments, and
#' interpolates all embedded expressions as explained in the \sQuote{Details}.
#' Named arguments are treated as locally defined variables, and are added to
#' (and override, in case of name reuse) names defined in the calling scope.
#' @details
#' \code{fmt} interpolates embedded expressions in a string.
#' \code{chr} converts a value to a character vector; unlike
#' \code{as.character}, it correctly deparses unevaluated names and expressions.
#' \code{interleave} is a helper that interleaves two vectors \code{a = c(a[1],
#' \dots, a[n])} and \code{b = c(b[1], \dots, b[n - 1])}.
#'
#' The general format of an interpolation expression inside a \code{fmt} string
#' is: \code{\{\dots\}} interpolates the expression \code{\dots}. To insert
#' literal braces, double them (i.e. \code{\{\{}, \code{\}\}}). Interpolated
#' expressions can optionally be followed by a \emph{format modifier}: if
#' present, it is specified via the syntax \code{\{\dots;modifier\}}. The
#' following modifiers are supported:
#' \describe{
#'  \item{\code{\"}}{like \code{dQuote(\dots)}}
#'  \item{\code{\'}}{like \code{sQuote(\dots)}}
#'  \item{\code{‹fmt›f}}{like \code{sprintf('\%‹fmt›f', \dots)}}
#' }
#' Vectors of length > 1 will be concatenated as if using
#' \code{\link[base]{toString}} before interpolation.
#' @keywords internal
fmt = function (..., envir = parent.frame()) {
    dots = list(...)
    named = nzchar(names(dots))
    str = paste(unlist(dots[(! named) %||% TRUE]), collapse = '')
    vars = dots[named]

    matches = gregexpr(
        '(?<op>\\{\\{)|(?<cp>\\}\\})|\\{(?<expr>[^};]+)(;(?<mod>[^}]+))?\\}',
        str,
        perl = TRUE
    )[[1L]]

    if (matches[[1L]] == -1L) return(str)

    glue = regmatches(str, list(matches), invert = TRUE)[[1L]]
    pos = attr(matches, 'capture.start')
    len = attr(matches, 'capture.length')
    what = attr(matches, 'capture.names')[apply(pos, 1L, Position, f = identity)]

    interp = map_chr(function (row) {
        switch(
            what[row],
            op = '{',
            cp = '}',
            {
                p = Find(identity, pos[row, ])
                l = Find(identity, len[row, ])
                expr = substr(str, p, p + l - 1L)
                val = eval(str2lang(expr), envir = vars, enclos = envir)

                mod = pos[row, 'mod']
                res = if (mod == 0L) {
                    chr(val)
                } else {
                    fmt = substr(str, mod, mod + len[row, 'mod'] - 1L);
                    switch(
                        substr(fmt, nchar(fmt), nchar(fmt)),
                        `"` = dQuote(chr(val)),
                        `'` = sQuote(chr(val)),
                        f = sprintf(paste0('%', fmt), val),
                        throw('unrecognized format modifier {fmt;"}')
                    )
                }
                paste(res, collapse = ', ')
            }
        )
    }, seq_along(what))

    paste(interleave(glue, interp), collapse = '')
}

#' @return \code{chr(x)} returns a string representation of a value or
#' unevaluated expression \code{x}.
#' @rdname fmt
chr = function (x) {
    UseMethod('chr')
}

chr.default = function (x) {
    as.character(x)
}

chr.call =
chr.for =
chr.if =
chr.while =
`chr.(` =
`chr.{` =
`chr.=` = function (x) {
    deparse1(x)
}

# Needs to be defined with `value` as the second argument to silence a spurious
# R CMD check warning in R ≤ 4.1:
#   The argument of a replacement function which corresponds to the right hand
#   side must be named ‘value’.
`chr.<-` = function (x, value) {
    deparse1(x)
}

chr.expression = function (x) {
    chr(x[[1L]])
}

chr.name = function (x) {
    deparse1(x, backtick = TRUE)
}

#' @return \code{html_escape(x)} returns the HTML-escaped version of \code{x}.
#' @rdname fmt
html_escape = function (x) {
    from = c('&', '<', '>', '"', "'")
    to = c('&amp;', '&lt;', '&gt;', '&quot;', '&apos;')
    substitutions = transpose(from, to)
    Reduce(function (x, r) gsub(r[1L], r[2L], x), substitutions, x)
}

#' @return \code{interleave(a, b)} returns a vector \code{c(a[1], b[1], a[2],
#' b[2], \dots, a[n - 1], b[n - 1], a[n])}.
#' @rdname fmt
interleave = function (a, b) {
    index = order(c(seq_along(a), seq_along(b)))
    c(a, b)[index]
}

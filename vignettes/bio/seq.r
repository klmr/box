#' Biological sequences
#'
#' The \code{bio/seq} module provides a type for representing DNA sequences.
'.__module__.'

#' Test whether input is valid biological sequence
#' @param seq a character vector or \code{seq} object
#' @name seq
#' @export
is_valid = function (seq) {
    UseMethod('is_valid')
}

is_valid.default = function (seq) {
    nucleotides = unlist(strsplit(seq, ''))
    nuc_index = match(nucleotides, c('A', 'C', 'G', 'T'))
    ! any(is.na(nuc_index))
}

`is_valid.bio/seq` = function (seq) {
    TRUE
}

#' Create a biological sequence
#'
#' \code{seq()} creates a set of nucleotide sequences from one or several
#' character vectors consisting of \code{A}, \code{C}, \code{G} and \code{T}.
#' @param ... optionally named character vectors representing DNA sequences.
#' @return Biological sequence equivalent to the input string.
#' @export
seq = function (...) {
    x = toupper(c(...))
    stopifnot(is_valid(x))
    structure(x, class = 'bio/seq')
}

#' Print one or more biological sequences
`print.bio/seq` = function (x) {
    box::use(stringr[str_trunc])

    if (is.null(names(x))) names(x) = paste('seq', seq_along(x))

    cat(
        sprintf('%d DNA sequence%s:\n', length(x), if (length(x) == 1L) '' else 's'),
        sprintf('  >%s\n  %s\n', names(x), str_trunc(x, 30L)),
        sep = ''
    )
    invisible(x)
}

box::register_S3_method('print', 'bio/seq', `print.bio/seq`)

#' Reverse complement
#'
#' The reverse complement of a sequence is its reverse, with all nucleotides
#' substituted by their base complement.
#' @param seq character vector of biological sequences
#' @name seq
#' @export
revcomp = function (seq) {
    nucleotides = strsplit(seq, '')
    complement = lapply(nucleotides, chartr, old = 'ACGT', new = 'TGCA')
    revcomp = lapply(complement, rev)
    seq(vapply(revcomp, paste, character(1L), collapse = ''))
}

#' Tabulate nucleotides present in sequences
#' @param seq sequences
#' @return A \code{\link[base::table]{table}} for the nucleotides of each
#'  sequence in the input.
#' @name seq
#' @export
table = function (seq) {
    box::use(stats[set_names = setNames])
    nucleotides = lapply(strsplit(seq, ''), factor, c('A', 'C', 'G', 'T'))
    set_names(lapply(nucleotides, base::table, dnn = NULL), names(seq))
}

if (is.null(box::name())) {
    box::use(./`__tests__`)
}

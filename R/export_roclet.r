export_roclet = function () {
    roxygen2::roclet('export')
}

#' @importFrom roxygen2 roclet_tags
#' @export
roclet_tags.roclet_export = function (x) {
    # This is different from Roxygen2’s definition of an export tag. This is
    # intentional: modules has a different export mechanism.
    list(export = roxygen2::tag_toggle)
}

#' @importFrom roxygen2 roclet_process
#' @export
roclet_process.roclet_export = function (x, parsed, base_path, global_options = list()) {
    is_block_exported = function (block) {
        'export' %in% names(block)
    }

    block_alias = function (block) {
        if ('object' %in% names(block))
            block$object$alias
        else
            ''
    }

    setNames(lapply(parsed$blocks, is_block_exported),
             vapply(parsed$blocks, block_alias, character(1)))
}

#' @importFrom roxygen2 roclet_output
#' @export
roclet_output.roclet_export = function (x, results, base_path, ..., is_first = FALSE) { }

#' @importFrom roxygen2 roclet_clean
#' @export
roclet_clean.roclet_export = function (x, base_path) { }

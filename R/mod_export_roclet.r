mod_export_roclet = function () {
    roxygen2::roclet('mod_export')
}

#' @importFrom roxygen2 roclet_tags
#' @export
roclet_tags.roclet_mod_export = function (x) {
    # This is different from Roxygen2’s definition of an export tag. This is
    # intentional: modules has a different export mechanism.
    list(export = roxygen2::tag_toggle)
}

#' @importFrom roxygen2 roclet_process
#' @export
roclet_process.roclet_mod_export = function (
    x, blocks, env, base_path, global_options = list()
) {
    is_exported = function (block) 'export' %in% names(block)
    name = function (block) attr(block, 'object')$alias

    setNames(
        vapply(blocks, is_exported, logical(1L)),
        vapply(blocks, name, character(1L))
    )
}

#' @importFrom roxygen2 roclet_output
#' @export
roclet_output.roclet_mod_export = function (x, results, base_path, ..., is_first = FALSE) { }

#' @importFrom roxygen2 roclet_clean
#' @export
roclet_clean.roclet_mod_export = function (x, base_path) { }

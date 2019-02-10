#' Mark module names to be exported
#'
#' @note
#' There are two situations in which the \code{@export} tag can be applied:
#' \enumerate{
#'   \item When applied to assignments, the assigned name is exported.
#'   \item When applied to a \code{mod::use} call, the imported names are
#'     exported. This can be the module name itself, any attached names, or
#'     both. All names introduced by the \code{mod::use} call are exported. See
#'     \code{\link[use]{mod::use}} for the rules governing what names are
#'     introduced into the scope, and thus exported.
#' }
#' In any other situation, applying the \code{@export} tag is an error.
#' @keywords internal
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

use_call = quote(mod::use)

assignment_calls = c('<-', '=', 'assign', '<<-')

is_assign_call = function (call) {
    deparse(call) %in% assignment_calls
}

block_is_assign = function (block) {
    is_assign_call(attr(block, 'call')[[1L]])
}

block_is_import = function (block) {
    identical(attr(block, 'call')[[1L]], use_call)
}

block_is_exported = function (block) {
    'export' %in% names(block)
}

block_name = function (block) {
    attr(block, 'object')$alias %||% ''
}

#' @importFrom roxygen2 roclet_process
#' @export
roclet_process.roclet_mod_export = function (
    x, blocks, env, base_path, global_options = list()
) {
    exports = vapply(blocks, block_is_exported, logical(1L))
    assignments = vapply(blocks, block_is_assign, logical(1L)) & exports
    imports = vapply(blocks, block_is_import, logical(1L)) & exports

    if (sum(assignments) + sum(imports) != sum(exports)) {
        block_is_invalid = function (block) {
            ! block_is_assign(block) && ! block_is_import(block)
        }
        first_invalid = Filter(block_is_invalid, blocks)[[1L]]
        first_invalid_call = deparse(attr(first_invalid, 'call'), backtick = TRUE)
        location = attr(first_invalid, 'location')[1L]
        msg = paste0(
            'The %s tag may only be applied to assignments or import ',
            'statements.\nUsed incorrectly in line %d:\n    %s'
        )
        stop(sprintf(msg, dQuote('@export'), location, first_invalid_call))
    }

    structure(
        blocks,
        assignments = assignments,
        imports = imports,
        names = vapply(blocks, block_name, character(1L)),
        class = 'mod_export_spec'
    )
}

print.mod_export_spec = function (x, ...) {
    exported_names = names(x[attr(x, 'assignments')])
    exported_imports = x[attr(x, 'imports')]
    cat('Exported names:', paste(exported_names, collapse = ', '))
    cat('\n\n')
    cat('Re-exported declarations:\n')
    import_code = vapply(exported_imports, function (i) deparse(attr(i, 'call')), character(1L))
    cat(paste('*', import_code, collapse = '\n'))
    cat('\n')
}

#' @importFrom roxygen2 roclet_output
#' @export
roclet_output.roclet_mod_export = function (x, ...) { }

#' @importFrom roxygen2 roclet_clean
#' @export
roclet_clean.roclet_mod_export = function (x, base_path) { }

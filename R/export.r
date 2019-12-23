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

#' @importFrom roxygen2 roclet_process
#' @export
roclet_process.roclet_mod_export = function (
    x, blocks, env, base_path, global_options = list()
) {
    blocks[vapply(blocks, block_is_exported, logical(1L))]
}

#' @importFrom roxygen2 roclet_output
#' @export
roclet_output.roclet_mod_export = function (x, ...) {}

#' @importFrom roxygen2 roclet_clean
#' @export
roclet_clean.roclet_mod_export = function (x, base_path) {}

parse_export_specs = function (info, mod_ns) {
    parse_export = function (export) {
        if (block_is_assign(export)) {
            block_name(export)
        } else if (block_is_use_call(export)) {
            imports = attr(export, 'call')[-1L]
            aliases = names(imports) %||% character(length(imports))
            flatmap_chr(reexport_names, imports, aliases, list(export))
        } else {
            block_error(export)
        }
    }

    reexport_names = function (declaration, alias, export) {
        spec = parse_spec(declaration, alias)
        import_ns = find_matching_import(namespace_info(mod_ns, 'imports'), spec)
        info = attr(import_ns, 'info')

        if (is_mod_still_loading(info)) {
            if (! is.null(spec$attach)) {
                msg = paste0(
                    'Invalid attempt to export names from an incompletely ',
                    'loaded, cyclic import (module %s) in line %d.'
                )
                stop(sprintf(msg, dQuote(spec$name), attr(export, 'location')[1L]))
            }

            return(spec$alias)
        }

        export_names = mod_export_names(info, import_ns)
        real_alias = if (is.null(spec$attach) || spec$explicit) spec$alias
        c(names(attach_list(spec, export_names)), real_alias)
    }

    find_matching_import = function (imports, reexport) {
        for (import in imports) {
            if (identical(attr(import, 'spec'), reexport)) return(import)
        }
    }

    block_error = function (export) {
        code = deparse(attr(export, 'call'), backtick = TRUE)
        location = attr(export, 'location')[1L]
        msg = paste0(
            'The %s tag may only be applied to assignments or use ',
            'statements.\nUsed incorrectly in line %d:\n    %s'
        )
        stop(sprintf(msg, dQuote('@export'), location, code))
    }

    exports = parse_roxygen_tags(info, mod_ns, mod_export_roclet())
    unique(flatmap_chr(parse_export, exports))
}

use_call = quote(mod::use)

assignment_calls = c(quote(`<-`), quote(`=`), quote(assign), quote(`<<-`))

is_assign_call = function (call) {
    any(vapply(assignment_calls, identical, logical(1L), call))
}

block_is_assign = function (block) {
    is_assign_call(attr(block, 'call')[[1L]])
}

block_is_use_call = function (block) {
    identical(attr(block, 'call')[[1L]], use_call)
}

block_is_exported = function (block) {
    'export' %in% names(block)
}

block_name = function (block) {
    attr(block, 'object')$alias
}

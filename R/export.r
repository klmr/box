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
            call = attr(export, 'call')
            aliases = names(call) %||% rep(list(NULL), length(call))
            Map(reexport_names, call[-1L], aliases[-1L], USE.NAMES = FALSE)
        } else {
            block_error(export)
        }
    }

    reexport_names = function (declaration, alias) {
        spec = parse_spec(declaration, alias)
        import_ns = find_matching_import(namespace_info(mod_ns, 'imports'), spec)
        info = attr(import_ns, 'info')

        if (is_mod_still_loading(info)) {
            caller = parent.frame()
            defer(spec, info, import_ns, caller)
        }

        exports = mod_exports(info, spec, import_ns)
        real_alias = if (is.null(spec$attach) || spec$explicit) spec$alias
        c(names(attach_list(spec, exports)), real_alias)
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
    tryCatch(
        unique(unlist(lapply(exports, parse_export))),
        defer = function (e) {
            # do.call(defer_import_finalization, e$args)
            NULL
        }
    )
    # tryCatch(
    #     withRestarts(
    #         unlist(lapply(exports, parse_export)),
    #         defer = defer_import_finalization_and_stop
    #     ),
    #     deferred = function (.) NULL
    # )
}

use_call = quote(mod::use)

assignment_calls = c('<-', '=', 'assign', '<<-')

is_assign_call = function (call) {
    deparse(call) %in% assignment_calls
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

defer = function (...) {
    nullcond = list(message = NULL, call = NULL, args = list(...))
    defer_condition = structure(nullcond, class = c('defer', 'condition'))
    signalCondition(defer_condition)
}

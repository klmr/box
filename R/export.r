#' Find exported names in parsed module source
#'
#' @param info The module info.
#' @param exprs The list of expressions of the parsed module.
#' @param mod_ns The module namespace after evaluating the expressions.
#' @return \code{parse_export_specs} returns a potentially empty character
#' vector of exported names.
#'
#' @note
#' There are two situations in which the \code{@export} tag can be applied:
#' \enumerate{
#'   \item When applied to assignments, the assigned name is exported.
#'   \item When applied to a \code{xyz::use} call, the imported names are
#'     exported. This can be the module name itself, any attached names, or
#'     both. All names introduced by the \code{xyz::use} call are exported. See
#'     \code{\link[xyz]{use}} for the rules governing what names are introduced
#'     into the scope, and thus exported.
#' }
#' In any other situation, applying the \code{@export} tag is an error.
#' @keywords internal
parse_export_specs = function (info, exprs, mod_ns) {
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

    exports = parse_export_tags(info, exprs, mod_ns)
    unique(flatmap_chr(parse_export, exports))
}

#' @keywords internal
#' @rdname parse_export_specs
use_call = quote(xyz::use)

#' @keywords internal
#' @rdname parse_export_specs
assignment_calls = c(quote(`<-`), quote(`=`), quote(assign), quote(`<<-`))

#' @param call A call to test.
#' @keywords internal
#' @rdname parse_export_specs
is_assign_call = function (call) {
    any(map_lgl(identical, assignment_calls, call))
}

#' @param block A roxygen2 block to inspect.
#' @keywords internal
#' @rdname parse_export_specs
block_is_assign = function (block) {
    is_assign_call(attr(block, 'call')[[1L]])
}

#' @keywords internal
#' @rdname parse_export_specs
block_is_use_call = function (block) {
    identical(attr(block, 'call')[[1L]], use_call)
}

#' @keywords internal
#' @rdname parse_export_specs
block_is_exported = function (block) {
    'export' %in% names(block)
}

#' @keywords internal
#' @rdname parse_export_specs
block_name = function (block) {
    attr(block, 'object')$alias
}

#' Extract comment tags from Roxygen block comments
#'
#' @param exprs The unevaluated expressions to parse.
#' @note The following code performs the same function as roxygen2 with a custom
#' \code{@} tag roclet. Unfortunately roxygen2 itself pulls in many
#' dependencies, making it less suitable for an infrastructure package such as
#' this one. Furthermore, the code license of roxygen2 is incompatible with
#' ours, so we cannot simply copy and paste the relevant code out. Luckily the
#' logic is straightforward to reimplement.
#' @keywords internal
parse_export_tags = function (info, exprs, mod_ns) {
    refs = utils::getSrcref(exprs)
    comment_refs = add_comments(refs)
    is_exported = map_lgl(has_export_tag, comment_refs)
    map(create_export_block, exprs[is_exported], refs[is_exported], list(info), list(mod_ns))
}

#' Collect export tag information
#'
#' @param expr The unevaluated expression represented by the tag.
#' @param ref The code reference \code{srcref} represented by the tag.
#' @note This could be represented much simpler but we keep compatibility with
#' roxygen2 — at least for the time being — to make integration with the
#' roxygen2 API easier, should it become necessary.
#' @keywords internal
create_export_block = function (expr, ref, info, mod_ns) {
    structure(
        list(export = ''),
        filename = attr(ref, 'srcfile')$filename,
        location = as.vector(ref),
        call = expr,
        object = parse_object(info, expr, mod_ns),
        class = 'roxy_block'
    )
}

#' @keywords internal
#' @rdname create_export_block
parse_object = function (info, expr, mod_ns) {
    if (is.character(expr)) {
        if (identical(expr, '_PACKAGE')) {
            value = list(path = info$source_path)
            roxygen2_object(value, expr, 'package')
        } else {
            roxygen2_object(expr, expr, 'data')
        }
    } else if (is.call(expr)) {
        if (is_assign_call(expr[[1L]])) {
            name = as.character(expr[[2L]])
            value = get(name, mod_ns)
            # FIXME: Add handling for S3
            roxygen2_object(value, name, 'function')
        } else if (identical(expr[[1L]], use_call)) {
            roxygen2_object(list(pkg = 'xyz', fun = 'use'), 'use', 'import')
        } else {
            # We do not care about the rest.
            NULL
        }
    } else {
        NULL
    }
}

#' @param value The object value.
#' @param alias The object name.
#' @param type The object type.
#' @keywords internal
#' @rdname create_export_block
roxygen2_object = function (value, alias, type) {
    structure(
        list(alias = alias, value = value, methods = NULL, topic = alias),
        class = paste0('roxygen2_', c(type, 'object'))
    )
}

#' Extend code regions to include leading comments and whitespace
#'
#' @param refs The code region \code{srcref}s to extend.
#' @keywords internal
add_comments = function (refs) {
    block_end_lines = map_int(`[[`, refs, 3L)
    block_end_bytes = map_int(`[[`, refs, 4L)
    block_start_lines = c(1L, block_end_lines[-length(block_end_lines)] + 1L)
    srcfile = attr(refs[[1L]], 'srcfile')
    llocs = map(c, block_start_lines, list(1L), block_end_lines, block_end_bytes)
    map(srcref, list(srcfile), llocs)
}

#' Find \code{@export} tags in code regions
#'
#' @param ref The code region \code{srcref} to search.
#' @return \code{TRUE} if the given region is annotated with a \code{@export}
#' tag, \code{FALSE} otherwise.
#' @keywords internal
has_export_tag = function (ref) {
    next_char = function () {
        pos <<- pos + 1L
        substr(line, pos, pos)
    }

    consume_char = function (chars) {
        matched = next_char() %in% chars
        if (! matched) pos <<- pos - 1L
        matched
    }

    consume_chars = function (chars) {
        while (pos != nchar(line) && consume_char(chars)) {}
    }

    consume_whitespace = function () {
        consume_chars(c(' ', '\t'))
    }

    is_roxygen_comment = function () {
        prev = pos
        consume_whitespace()
        if (! consume_char('#')) return(FALSE)
        consume_chars('#')
        if (! consume_char("'")) {
            pos <<- prev
            return(FALSE)
        }
        consume_whitespace()
        TRUE
    }

    is_empty_or_comment = function () {
        consume_whitespace()
        pos == nchar(line) || consume_char('#')
    }

    is_export = function () {
        pos <<- pos + 1L
        len = nchar('@export')
        substr(line, pos, pos + len) == '@export' &&
            (pos + len > nchar(line) || substr(line, pos + len, pos + len) %in% c(' ', '\t'))
    }

    block = as.character(ref)
    for (line in block) {
        pos = 0L
        if (! is_roxygen_comment()) {
            if (is_empty_or_comment()) next else return(FALSE)
        }
        if (is_export()) return(TRUE)
    }
    FALSE
}

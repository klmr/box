#' Explicitly declare module exports
#'
#' \code{box::export} explicitly marks a source file as a \pkg{box} module. If
#' can be used as an alternative to the \code{@export} tag comment to declare a
#' module’s exports.
#'
#' @usage \special{box::export(\dots)}
#' @param \dots zero or more unquoted names that should be exported from the
#' module.
#' @return \code{box::export} has no return value. It is called for its
#' side effect.
#'
#' @details
#' \code{box::export} can be called inside a module to specify the module’s
#' exports. If a module contains a call to \code{box::export}, this call
#' overrides any declarations made via the \code{@export} tag comment. When a
#' module contains multiple calls to \code{box::export}, the union of all thus
#' defined names is exported.
#'
#' A module can also contain an argument-less call to \code{box::export}. This
#' ensures that the module does not export any names. Otherwise, a module that
#' defines names but does not mark them as exported would be treated as a
#' \emph{legacy module}, and all default-visible names would be exported from
#' it. Default-visible names are names not starting with a dot (\code{.}).
#' Another use of \code{box::export()} is to enable a module without exports to
#' use \link[=mod-hooks]{module event hooks}.
#'
#' @note The preferred way of declaring exports is via the \code{@export} tag
#' comment. The main purpose of \code{box::export} is to explicitly prevent
#' exports, by being called without arguments.
#'
#' @seealso
#' \code{\link[=use]{box::use}} for information on declaring exports via
#' \code{@export}.
#' @export
export = function (...) {
    mod_ns = mod_topenv(parent.frame())
    if (! is_namespace(mod_ns)) {
        throw('{"export";"} can only be called from inside a module')
    }

    names = as.list(match.call())[-1L]
    for (name in names) {
        if (! is.name(name)) {
            throw(
                '{"export()";"} requires a list of unquoted names; ',
                '{name;"} is not a name'
            )
        }
    }

    namespace_info(mod_ns, 'exports') = union(
        namespace_info(mod_ns, 'exports'),
        as.character(unlist(names))
    )
    namespace_info(mod_ns, 'legacy') = FALSE
    invisible()
}

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
#'   \item When applied to a \code{box::use} call, the imported names are
#'     exported. This can be the module name itself, any attached names, or
#'     both. All names introduced by the \code{box::use} call are exported. See
#'     \code{\link[box]{use}} for the rules governing what names are introduced
#'     into the scope, and thus exported.
#' }
#' In any other situation, applying the \code{@export} tag is an error.
#' @keywords internal
parse_export_specs = function (info, exprs, mod_ns) {
    parse_export = function (export) {
        if (block_is_use_call(export)) {
            imports = attr(export, 'call')[-1L]
            aliases = names(imports) %||% character(length(imports))
            flatmap_chr(reexport_names, imports, aliases, list(export))
        } else {
            # Attempt to extract a name from an arbitrary expressions.
            block_name(export) %||% block_error(export)
        }
    }

    reexport_names = function (declaration, alias, export) {
        # Permit empty expression resulting from trailing comma.
        if (identical(declaration, quote(expr =)) && identical(alias, '')) return()
        spec = parse_spec(declaration, alias)
        import = find_matching_import(namespace_info(mod_ns, 'imports'), spec)

        if (is_mod_still_loading(import$info)) {
            if (! is.null(spec$attach)) {
                throw(
                    'invalid attempt to export names from an incompletely ',
                    'loaded, cyclic import (module {name;"}) in line {line}',
                    name = spec$name,
                    line = attr(export, 'location')[1L]
                )
            }

            return(spec$alias)
        }

        export_names = mod_export_names(import$info, import$ns)
        real_alias = if (is.null(spec$attach) || spec$explicit) spec$alias
        c(names(attach_list(spec, export_names)), real_alias)
    }

    find_matching_import = function (imports, reexport) {
        for (import in imports) {
            if (identical(import$spec, reexport)) return(import)
        }
    }

    exports = parse_export_tags(info, exprs, mod_ns)
    unique(flatmap_chr(parse_export, exports))
}

block_error = function (export) {
    throw(
        'the {"@export";"} tag may only be applied to assignments or ',
        '{"use";"} declarations;\n',
        'used incorrectly in line {location}:\n',
        '    {paste(code, collapse = "\n    ")}',
        code = deparse(attr(export, 'call'), backtick = TRUE),
        location = attr(export, 'location')[1L]
    )
}

#' @keywords internal
#' @rdname parse_export_specs
use_call = quote(box::use)

#' @keywords internal
#' @rdname parse_export_specs
static_assign_calls = c(quote(`<-`), quote(`=`), quote(`:=`), quote(`<<-`))

#' @keywords internal
#' @rdname parse_export_specs
assign_calls = c(static_assign_calls, quote(assign), quote(makeActiveBinding))

#' @param call A call to test.
#' @keywords internal
#' @rdname parse_export_specs
is_static_assign_call = function (call) {
    any(map_lgl(identical, static_assign_calls, call))
}

#' @keywords internal
#' @rdname parse_export_specs
is_assign_call = function (call) {
    any(map_lgl(identical, assign_calls, call))
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
#' @return \code{parse_export_tags} returns a list of \code{roxy_block}s for all
#' exported declarations.
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
#' @return \code{create_export_block} returns an object of type
#' \code{roxy_block} represents an exported declaration expression, along with
#' its source code location.
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
            roxygen2_object(expr, value, 'package')
        } else {
            roxygen2_object(expr, expr, 'data')
        }
    } else if (is.call(expr)) {
        if (identical(expr[[1L]], use_call)) {
            roxygen2_object('use', list(pkg = 'box', fun = 'use'), 'import')
        } else {
            # Attempt to extract a name from the LHS: recurse until the
            # left-most token is a name or character literal (this is necessary
            # because `"a" = 1` is valid R; but also to allow `assign` and
            # `makeActiveBinding` calls).
            while (is.call(expr) && length(expr) > 1L) {
                if (is.name(expr[[2L]]) || is.character(expr[[2L]])) {
                    name = if (is_static_assign_call(expr[[1L]])) {
                        as.character(expr[[2L]])
                    } else {
                        # `assign(…)`, `makeActiveBinding(…)` and similar.
                        eval(expr[[2L]], mod_ns)
                    }

                    obj = if (bindingIsActive(name, mod_ns)) {
                        roxygen2_object(name, activeBindingFunction(name, mod_ns), 'active')
                    } else {
                        value = get(name, mod_ns)
                        if (is.function(value)) {
                            # FIXME: Add handling for S3
                            roxygen2_object(name, value, 'function')
                        } else {
                            roxygen2_object(name, value, NULL)
                        }
                    }
                    return(obj)
                }
                expr = expr[[2L]]
            }
            # We do not care about the rest.
            NULL
        }
    } else {
        NULL
    }
}

#' @param alias The object name.
#' @param value The object value.
#' @param type The object type.
#' @keywords internal
#' @rdname create_export_block
roxygen2_object = function (alias, value, type) {
    structure(
        list(alias = alias, value = value, methods = NULL, topic = alias),
        class = paste0('roxygen2_', c(type, 'object'))
    )
}

#' Extend code regions to include leading comments and whitespace
#'
#' @param refs a list of the code region \code{srcref}s to extend.
#' @return \code{add_comment} returns a list of \code{srcref}s corresponding to
#' \code{srcref}, but extended to include the preceding comment block.
#' @keywords internal
add_comments = function (refs) {
    if (length(refs) == 0L) return(list())

    block_end_lines = map_int(`[[`, refs, 3L)
    block_end_bytes = map_int(`[[`, refs, 4L)
    block_start_lines = c(1L, block_end_lines[-length(block_end_lines)] + 1L)
    srcfiles = map(attr, refs, 'srcfile')
    llocs = map(c, block_start_lines, 1L, block_end_lines, block_end_bytes)
    map(srcref, srcfiles, llocs)
}

#' Find \code{@export} tags in code regions
#'
#' @param ref The code region \code{srcref} to search.
#' @return \code{TRUE} if the given region is annotated with a \code{@export}
#' tag, \code{FALSE} otherwise.
#' @keywords internal
has_export_tag = function (ref) {
    self = environment()

    next_char = function () {
        self$pos = pos + 1L
        substr(line, pos, pos)
    }

    consume_char = function (chars) {
        matched = next_char() %in% chars
        if (! matched) self$pos = pos - 1L
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
            self$pos = prev
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
        self$pos = pos + 1L
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

# Module/package specification expression grammar as a PEG, approximating the R
# parse tree:
#
# mod_spec    → pkg_name (“[” attach_spec “]”)? !“/” /
#               mod
# pkg_name    → identifier
# mod         → mod_prefix “/” mod_name (“[” attach_spec “]”)?
# mod_prefix  → identifier !“/” /
#               mod_prefix “/” identifier
# mod_name    → identifier
# attach_spec → “...” /
#               attach_list
# attach_list → identifier (“,” identifier)+
# identifier  → ‹valid R identifier›
#
# Note: This is missing the alias declaration, since that is not captured in the
# AST provided by R. It is instead handled separately.

#' Parse a mod spec expression passed to \code{use}
#'
#' @param expr the mod spec expression to parse
#' @return \code{parse_mod_spec} returns a named list that contains information
#' about the parsed mod specification. Currently it contains:
#' \describe{
#'  \item{\code{name}}{the module or package name}
#'  \item{\code{prefix}}{the prefix, if the spec is a module}
#'  \item{\code{attach}}{a named vector of symbols to attach, or
#'      \code{TRUE} to attach all symbols, or \code{NULL} to attach nothing}
#'  \item{\code{alias}}{the module or package alias}
#'  \item{\code{explicit}}{a logical value indicating whether the caller
#'      provided an explicit alias}
#' }
#' @keywords internal
parse_mod_spec = function (...) {
    expr = substitute(list(...))
    alias = names(expr[-1L])
    mod_spec = rethrow_on_error(
        parse_mod_spec_impl(expr[[2L]]),
        call = sys.call(-1L)
    )

    mod_spec(
        mod_spec,
        alias = alias %||% (mod_spec$mod %||% mod_spec$pkg)$name,
        explicit = ! is.null(alias)
    )
}

mod_spec = function (spec, ...) {
    is_pkg = 'pkg' %in% names(spec)
    base_spec = c(spec$mod, spec$pkg)
    additional_spec = spec[setdiff(names(spec), c('mod', 'pkg'))]
    structure(
        c(base_spec, additional_spec, ...),
        class = c(if (is_pkg) 'pkg_spec' else 'mod_spec', 'spec')
    )
}

is_mod_spec = function (x) {
    inherits(x, 'mod_spec')
}

is_pkg_spec = function (x) {
    inherits(x, 'pkg_spec')
}

mod_name = function (spec) {
    paste(paste(spec$prefix, collapse = '/'), spec$name, sep = '/')
}

print.spec = function (x, ...) {
    r_name = function (names) {
        vapply(
            names,
            function (n) sprintf('\x1b[33m%s\x1b[0m', deparse(as.name(n), backtick = TRUE)),
            character(1)
        )
    }

    format_attach = function (a) {
        with_alias = function (names, aliases) {
            mapply(
                function (n, a) if (identical(n, a)) n else paste(a, '=', n),
                names, aliases
            )
        }

        if (is.null(a)) {
            ''
        } else {
            list = if (isTRUE(a)) {
                '*'
            } else {
                aliased_names = with_alias(r_name(a), r_name(names(a)))
                paste0('[', toString(aliased_names), ']')
            }
            paste(', attach =', list)
        }
    }

    mod_or_pkg = function (spec) {
        if (is_mod_spec(spec)) {
            prefix = paste(r_name(spec$prefix), collapse = '/')
            sprintf('mod(%s/\x1b[4;33m%s\x1b[0m)', prefix, r_name(spec$name))
        } else {
            sprintf('pkg(\x1b[4;33m%s\x1b[0m)', r_name(spec$name))
        }
    }

    cat(sprintf(
        'mod_spec(%s%s%s)\n',
        if (x$explicit) paste(r_name(x$alias), '= ') else '',
        mod_or_pkg(x),
        format_attach(x$attach)
    ))

    invisible(x)
}

parse_mod_spec_impl = function (expr) {
    if (is.name(expr)) {
        c(parse_pkg_name(expr), list(attach = NULL))
    } else if (is.call(expr)) {
        if (identical(expr[[1]], quote(`[`))) {
            c(parse_pkg_name(expr[[2]]), parse_attach_spec(expr))
        } else if (identical(expr[[1]], quote(`/`))) {
            parse_mod(expr)
        } else {
            parse_error('Unexpected token in ', expr)
        }
    } else {
        parse_error('Unexpected token in ', expr)
    }
}

parse_pkg_name = function (expr) {
    list(pkg = list(name = parse_identifier(expr)))
}

parse_mod = function (expr) {
    prefix = parse_mod_prefix(expr[[2]])
    mod = expr[[3]]

    if (is.call(mod)) {
        if (identical(mod[[1]], quote(`[`))) {
            c(
                list(mod = c(parse_mod_name(mod[[2]]), prefix)),
                parse_attach_spec(mod)
            )
        } else {
            parse_error('Expected module name or attach list, got ', mod)
        }
    } else if (is.name(mod)) {
        list(mod = c(parse_mod_name(mod), prefix), attach = NULL)
    } else {
        parse_error('Expected module name or attach list, got ', mod)
    }
}

parse_mod_prefix = function (expr) {
    if (is.name(expr)) {
        list(prefix = deparse(expr))
    } else if (is.call(expr) && identical(expr[[1]], quote(`/`))) {
        if (! is.name(expr[[3]])) {
            parse_error('Expected identifier in module prefix, got ', expr[[3]])
        } else {
            suffix = deparse(expr[[3]])
            list(prefix = c(parse_mod_prefix(expr[[2]])$prefix, suffix))
        }
    } else {
        parse_error('Expected module prefix, got ', expr)
    }
}

parse_mod_name = function (expr) {
    list(name = parse_identifier(expr))
}

parse_attach_spec = function (expr) {
    assign_missing_names = function (lst) {
        setNames(lst, names(lst) %|% unlist(lst))
    }

    items = parse_attach_list(expr[-1][-1])
    if (length(items) == 1 && identical(items[[1]], '...')) {
        list(attach = TRUE)
    } else {
        list(attach = assign_missing_names(items))
    }
}

parse_attach_list = function (expr) {
    if (length(expr) == 1L && identical(expr[[1]], quote(expr = ))) {
        parse_error('Expected at least one identifier in attach list')
    } else {
        vapply(expr, parse_identifier, character(1))
    }
}

parse_identifier = function (expr) {
    if (length(expr) != 1L || ! is.name(expr)) {
        parse_error('Expected identifier, got ', expr)
    } else if (identical(expr, quote(expr = ))) {
        parse_error('Expected identifier, got nothing')
    } else {
        deparse(expr)
    }
}

parse_error = function (...) {
    chr = function (x) {
        if (is.recursive(x) || is.pairlist(x)) {
            deparse(x)
        } else {
            as.character(x)
        }
    }
    stop(vapply(list(...), chr, character(1)))
}

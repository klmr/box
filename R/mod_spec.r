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
#' @param alias the mod spec alias as a character, or \code{NULL}
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
parse_mod_spec = function (expr, alias) {
    mod_spec = rethrow_on_error(parse_mod_spec_impl(expr), call = sys.call(-2L))

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
    UseMethod('mod_name')
}

mod_name.mod_spec = function (spec) {
    paste(paste(spec$prefix, collapse = '/'), spec$name, sep = '/')
}

mod_name.pkg_spec = function (spec) {
    spec$name
}

print.spec = function (x, ...) {
    cat(as.character(x, ...), '\n', sep = '')
    invisible(x)
}

as.character.spec = function (x, ...) {
    r_name = function (names) {
        vapply(
            names,
            function (n) {
                if (is.na(n)) '…' else sprintf(
                    '\x1b[33m%s\x1b[0m',
                    deparse(as.name(n), backtick = TRUE)
                )
            },
            character(1L)
        )
    }

    format_attach = function (a) {
        with_alias = function (names, aliases) {
            mapply(
                function (n, a) if (n == '…' || identical(n, a)) n else paste(a, '=', n),
                names, aliases
            )
        }

        if (is.null(a)) {
            ''
        } else {
            aliased_names = with_alias(r_name(a), r_name(names(a)))
            paste(', attach =', paste0('[', toString(aliased_names), ']'))
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

    sprintf(
        'mod_spec(%s%s%s)',
        if (x$explicit) paste(r_name(x$alias), '= ') else '',
        mod_or_pkg(x),
        format_attach(x$attach)
    )
}

parse_mod_spec_impl = function (expr) {
    if (is.name(expr)) {
        c(parse_pkg_name(expr), list(attach = NULL))
    } else if (is.call(expr)) {
        if (identical(expr[[1L]], quote(`[`))) {
            c(parse_pkg_name(expr[[2L]]), parse_attach_spec(expr))
        } else if (identical(expr[[1L]], quote(`/`))) {
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
    prefix = parse_mod_prefix(expr[[2L]])
    mod = expr[[3L]]

    if (is.call(mod)) {
        if (identical(mod[[1L]], quote(`[`))) {
            c(
                list(mod = c(parse_mod_name(mod[[2L]]), prefix)),
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
    } else if (is.call(expr) && identical(expr[[1L]], quote(`/`))) {
        if (! is.name(expr[[3L]])) {
            parse_error('Expected identifier in module prefix, got ', expr[[3L]])
        } else {
            suffix = deparse(expr[[3L]])
            list(prefix = c(parse_mod_prefix(expr[[2L]])$prefix, suffix))
        }
    } else {
        parse_error('Expected module prefix, got ', expr)
    }
}

parse_mod_name = function (expr) {
    list(name = parse_identifier(expr))
}

parse_attach_spec = function (expr) {
    syms = parse_attach_list(expr[-1L][-1L])
    list(attach = assign_missing_names(syms))
}

assign_missing_names = function (syms) {
    x = setNames(syms, names(syms) %|% unlist(syms))
    x[x == '...'] = NA_character_

    if (any((dup = duplicated(names(x))))) {
        parse_error(
            'Cannot attach duplicate names, found duplicated ',
            paste(dQuote(unique(names(x)[dup])), collapse = ', ')
        )
    }
    if (any(names(syms)[is.na(x)] != '')) {
        parse_error('Wildcard imports cannot be aliased')
    }
    x
}

parse_attach_list = function (expr) {
    if (length(expr) == 1L && identical(expr[[1L]], quote(expr = ))) {
        parse_error('Expected at least one identifier in attach list')
    } else {
        vapply(expr, parse_identifier, character(1L))
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
    stop(simpleError(
        paste(vapply(list(...), chr, character(1L)), collapse = ''),
        call = sys.call(-1L)
    ))
}

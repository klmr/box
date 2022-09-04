# Module/package specification expression grammar as a PEG, approximating the R
# parse tree:
#
# spec        → pkg_name (“[” attach_spec “]”)? !“/” /
#               mod
# pkg_name    → name
# mod         → mod_prefix “/” mod_name (“[” attach_spec “]”)?
# mod_prefix  → name !“/” /
#               mod_prefix “/” name
# mod_name    → name
# attach_spec → “...” /
#               attach_list
# attach_list → name (“,” name)+
# name        → ‹valid R name›
#
# Note: This is missing the alias declaration, since that is not captured in the
# AST provided by R. It is instead handled separately.

#' Parse a mod or pkg spec expression passed to \code{use}
#'
#' @param expr the mod or pkg spec expression to parse
#' @param alias the mod or pkg spec alias as a character, or \code{NULL}
#' @return \code{parse_spec} returns a named list that contains information
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
#' @name spec
parse_spec = function (expr, alias) {
    spec = parse_spec_impl(expr)

    is_pkg = 'pkg' %in% names(spec)
    spec_type = if (is_pkg) pkg_spec else mod_spec
    name = spec[[if (is_pkg) 'pkg' else 'mod']]$name
    spec_type(spec, alias = alias %||% name, explicit = nzchar(alias))
}

#' @param spec named list of information the parser constructed from a given
#' spec expression
#' @param \dots further information about a spec, not represented by the spec
#' expression parse tree
#' @keywords internal
#' @name spec
mod_spec = function (spec, ...) {
    extra_spec = spec[setdiff(names(spec), 'mod')]
    structure(c(spec$mod, extra_spec, ...), class = c('box$mod_spec', 'box$spec'))
}

#' @keywords internal
#' @name spec
pkg_spec = function (spec, ...) {
    extra_spec = spec[setdiff(names(spec), 'pkg')]
    structure(c(spec$pkg, extra_spec, ...), class = c('box$pkg_spec', 'box$spec'))
}

#' @keywords internal
#' @name spec
spec_name = function (spec) {
    UseMethod('spec_name')
}

`spec_name.box$mod_spec` = function (spec) {
    paste(paste(spec$prefix, collapse = '/'), spec$name, sep = '/')
}

`spec_name.box$pkg_spec` = function (spec) {
    spec$name
}

#' @export
`print.box$spec` = function (x, ...) {
    cat(as.character(x, ...), '\n', sep = '')
    invisible(x)
}

#' @export
`as.character.box$spec` = function (x, ...) {
    r_name = function (names) {
        map_chr(
            function (n) {
                if (is.na(n)) '\u2026' else fmt('\x1b[33m{as.name(n)}\x1b[0m')
            },
            names
        )
    }

    format_attach = function (a) {
        with_alias = function (names, aliases) {
            mapply(
                function (n, a) if (n == '\u2026' || identical(n, a)) n else paste(a, '=', n),
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
        if (inherits(spec, 'box$mod_spec')) {
            prefix = paste(r_name(spec$prefix), collapse = '/')
            fmt('mod({prefix}/\x1b[4;33m{r_name(spec$name)}\x1b[0m)')
        } else {
            fmt('pkg(\x1b[4;33m{r_name(spec$name)}\x1b[0m)')
        }
    }

    fmt(
        'mod_spec({alias}{mod_or_pkg(x)}{format_attach(x$attach)})',
        alias = if (x$explicit) paste(r_name(x$alias), '= ') else ''
    )
}

parse_spec_impl = function (expr) {
    if (is.name(expr)) {
        if (identical(expr, quote(.))) {
            list(prefix = '.', name = '__init__')
        } else if (identical(expr, quote(..))) {
            list(prefix = '..', name = '.')
        } else {
            c(parse_pkg_name(expr), list(attach = NULL))
        }
    } else if (is.call(expr)) {
        if (identical(expr[[1L]], quote(`[`))) {
            if (is.name((name = expr[[2L]]))) {
                if (identical(name, quote(.))) {
                    c(list(prefix = '.', name = '__init__'), parse_attach_spec(expr))
                } else if (identical(name, quote(..))) {
                    # parse_mod(bquote(../.(`[[<-`(expr, 2L, quote(.)))))
                    c(list(prefix = '..', name = '.'), parse_attach_spec(expr))
                } else {
                    c(parse_pkg_name(name), parse_attach_spec(expr))
                }
            } else {
                throw('expected a name in {expr;"}, got {describe_token(name)}')
            }
        } else if (identical(expr[[1L]], quote(`/`))) {
            parse_mod(expr)
        } else {
            throw('expected {"/";"} in {expr;"}, got {expr[[1L]];"}')
        }
    } else {
        throw('expected a module or package name, got {describe_token(expr)}')
    }
}

parse_pkg_name = function (expr) {
    name = parse_name(expr)
    if (is.na(name)) {
        throw('alias without a name provided in use declaration')
    }
    list(pkg = list(name = name))
}

parse_mod = function (expr) {
    prefix = parse_mod_prefix(expr[[2L]])
    mod = expr[[3L]]

    # Runs of `..` from the start are valid; `..` in the middle is not:

    if (any(diff(which(c(TRUE, prefix$prefix == '..'))) > 1L)) {
        # At least one gap in the sequence of `..` from the start
        throw('{"..";"} can only be used as a prefix')
    }

    if ('.' %in% prefix$prefix[-1L]) {
        throw('{".";"} can only be used as a prefix')
    }

    if (is.call(mod)) {
        if (identical(mod[[1L]], quote(`[`))) {
            c(
                list(mod = c(parse_mod_name(mod[[2L]], prefix), prefix)),
                parse_attach_spec(mod)
            )
        } else {
            throw('expected a name in {expr;"}, got {describe_token(mod)}')
        }
    } else if (is.name(mod)) {
        list(mod = c(parse_mod_name(mod, prefix), prefix), attach = NULL)
    } else {
        throw('expected a name in {expr;"}, got {describe_token(mod)}')
    }
}

parse_mod_prefix = function (expr) {
    if (is.name(expr)) {
        list(prefix = deparse1(expr))
    } else if (is.call(expr) && identical(expr[[1L]], quote(`/`))) {
        if (! is.name(expr[[3L]])) {
            throw('expected a name in module prefix, got {describe_token(expr[[3L]])}')
        } else {
            suffix = deparse1(expr[[3L]])
            list(prefix = c(parse_mod_prefix(expr[[2L]])$prefix, suffix))
        }
    } else {
        throw('expected a module prefix, got {describe_token(expr)}')
    }
}

parse_mod_name = function (expr, prefix) {
    name = parse_name(expr)

    if (length((prefix = prefix$prefix)) > 0L) {
        dot_after_prefix = name == '.'
        back_inside_path = ! all(prefix == '..') && name == '..'

        if (dot_after_prefix || back_inside_path) {
            throw('{expr;"} can only be used as a prefix')
        }
    }

    list(name = name)
}

parse_attach_spec = function (expr) {
    syms = parse_attach_list(expr[-1L][-1L])
    list(attach = assign_missing_names(syms))
}

assign_missing_names = function (syms) {
    x = stats::setNames(syms, names(syms) %|% unlist(syms))
    x[x == '...'] = NA_character_

    if (any((dup = duplicated(names(x))))) {
        throw('cannot attach duplicate names, found duplicated {unique(names(x)[dup]);"}')
    }
    if (any(names(syms)[is.na(x)] != '')) {
        throw('wildcard imports cannot be aliased')
    }
    x
}

parse_attach_list = function (expr) {
    if (length(expr) == 1L && identical(expr[[1L]], quote(expr =))) {
        throw('expected at least one name in attach list')
    } else {
        names = stats::setNames(map_chr(parse_name, expr), names(expr))

        missing_names = is.na(names)
        if (any(missing_names)) {
            # Allow missing name for last, unnamed argument to allow “trailing
            # comma” syntax:
            #   box::use(./a[x, y, ])
            index = which(missing_names)
            if (
                length(index) != 1L ||
                index != length(names) ||
                nzchar(names(names)[index] %||% '')
            ) {
                throw('alias without a name provided in attach list')
            }

            names[-index]
        } else {
            names
        }
    }
}

parse_name = function (expr) {
    if (length(expr) != 1L || ! is.name(expr)) {
        throw('expected a name, got {describe_token(expr)}')
    } else {
        deparse1(expr) %||% NA_character_
    }
}

describe_token = function (expr) {
    fmt('{class(expr)} literal {expr;"}')
}

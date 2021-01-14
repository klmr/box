#' Parse a module’s documentation
#'
#' @param info The module info.
#' @param mod_ns The module namespace.
#' @return \code{parse_documentation} returns a list of character strings with
#' the Rd documentation source code for each documented name in a module.
#' @keywords internal
parse_documentation = function (info, mod_ns) {
    rdfiles = parse_roxygen_tags(info, mod_ns)
    # Due to aliases, documentation entries may have more than one name.
    aliases = map(function (rd) unique(rd$fields$alias$values), rdfiles)
    names = rep(names(rdfiles), lengths(aliases))
    docs = stats::setNames(rdfiles[names], unlist(aliases))

    lapply(docs, format, wrap = FALSE)
}

#' @keywords internal
#' @rdname parse_documentation
parse_roxygen_tags = function (info, mod_ns) {
    mod_path = info$source_path
    blocks = roxygen2::parse_file(mod_path, mod_ns)
    roxygen2::roclet_process(roxygen2::rd_roclet(), blocks, mod_ns, dirname(mod_path))
}

#' Display module documentation
#'
#' \code{help} displays help on a module’s objects and functions in much
#' the same way \code{\link[utils]{help}} does for package contents.
#'
#' @param topic fully-qualified name of the object or function to get help for,
#'  in the format \code{module$function}
#' @param help_type character string specifying the output format; currently,
#'  only \code{'text'} is supported
#' @rdname help
#' @export
#' @examples
#' \dontrun{
#' xyz::use(my/mod)
#' xyz::help(mod$func)
#' }
help = function (topic, help_type = getOption('help_type', 'text')) {
    topic = substitute(topic)
    top_module = help_topic_leftmost_name(topic)

    if (is.null(top_module) || ! exists(top_module, parent.frame())) {
        stop(
            dQuote(deparse(topic)), ' is not a valid module help topic',
            call. = FALSE
        )
    }

    mod_exports = get(top_module, parent.frame())
    info = attr(mod_exports, 'info')
    mod_name = strsplit(attr(mod_exports, 'name'), ':')[[1L]][2L]
    subject = as.character(topic[[3L]])

    if (inherits(info, 'xyz$pkg_info')) {
        help_call = bquote(help(topic = .(subject), package = .(mod_name)))
        return(call_help(help_call, parent.frame()))
    } else if (! inherits(info, 'xyz$mod_info')) {
        stop(
            dQuote(deparse(topic)), ' is not a valid module help topic',
            call. = FALSE
        )
    }

    if (! requireNamespace('roxygen2')) {
        stop('Displaying documentation requires roxygen2 installed.')
    }

    mod_ns = attr(mod_exports, 'namespace')
    all_docs = namespace_info(mod_ns, 'doc')
    if (is.null(all_docs)) {
        info = attr(mod_exports, 'info')
        all_docs = parse_documentation(info, mod_ns)
        namespace_info(mod_ns, 'doc') = all_docs
    }

    doc = all_docs[[subject]]
    if (is.null(doc)) {
        stop(
            'No documentation available for ', dQuote(subject),
            ' in module ', dQuote(mod_name),
            call. = FALSE
        )
    }

    display_help(doc, paste0('module:', mod_name), help_type)
}

help_topic_leftmost_name = function (expr) {
    # For nested modules, `topic` looks like this: `a$b$c…`. We need to retrieve
    # the first part of this (`a`) and check whether it’s a module.

    if (is.name(expr)) {
        as.character(expr)
    } else if (! is.call(expr) || expr[[1L]] != '$') {
        NULL
    } else {
        Recall(expr[[2L]])
    }
}

is_module_help_topic = function (topic, parent) {
    top_module = help_topic_leftmost_name(topic)

    ! is.null(top_module) &&
        exists(top_module, parent) &&
        inherits(get(top_module, parent), 'xyz$mod')
}

#' @usage
#' \special{?topic}
#' @inheritParams utils::`?`
#' @rdname help
#' @export
#' @examples
#' \dontrun{
#' ?mod$func
#' }
`?` = function (e1, e2) {
    topic = substitute(e1)
    if (
        missing(e2) && ! missing(e1) &&
        is_module_help_topic(topic, parent.frame())
    ) {
        eval.parent(call('help', topic))
    } else {
        call_help(match.call(), parent.frame())
    }
}

call_help = function (call, parent) {
    type = as.character(call[[1L]])
    call[[1L]] = if ('devtools_shims' %in% search()) {
        get(type, pos = 'devtools_shims')
    } else {
        get(type, pos = 'package:utils')
    }
    eval(call, envir = parent)
}

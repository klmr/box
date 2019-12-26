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
    docs = setNames(rdfiles[names], unlist(aliases))
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
#' \code{module_help} displays help on a module’s objects and functions in much
#' the same way \code{\link[utils]{help}} does for package contents.
#'
#' @param topic fully-qualified name of the object or function to get help for,
#'  in the format \code{module$function}
#' @param help_type character string specifying the output format; currently,
#'  only \code{'text'} is supported
#' @note Help is only available if \code{\link{import}} loaded the help stored
#' in the module file(s). By default, this happens only in interactive sessions.
#' @rdname help
#' @export
#' @examples
#' \dontrun{
#' mod = import('mod')
#' module_help(mod$func)
#' }
module_help = function (topic, help_type = getOption('help_type', 'text')) {
    if (! requireNamespace('roxygen2')) {
        stop('Displaying documentation requires roxygen2 installed.')
    }

    topic = substitute(topic)

    if (! is_module_help_topic(topic, parent.frame())) {
        stop(
            dQuote(deparse(topic)), ' is not a valid module help topic',
            call. = FALSE
        )
    }

    mod_exports = get(as.character(topic[[2L]]), parent.frame())
    module_name = module_name(mod_exports)
    object = as.character(topic[[3L]])

    mod_ns = attr(mod_exports, 'namespace')
    all_docs = namespace_info(mod_ns, 'doc')
    if (is.null(all_docs)) {
        info = attr(mod_exports, 'info')
        all_docs = parse_documentation(info, mod_ns)
        namespace_info(mod_ns, 'doc') = all_docs
    }

    doc = all_docs[[object]]
    if (is.null(doc)) {
        stop(
            'No documentation available for ', dQuote(object),
            ' in module ', dQuote(module_name),
            call. = FALSE
        )
    }

    display_help(doc, paste0('module:', module_name), help_type)
}

is_module_help_topic = function (topic, parent) {
    # For nested modules, `topic` looks like this: `a$b$c…`. We need to retrieve
    # the first part of this (`a`) and check whether it’s a module.

    leftmost_name = function (expr) {
        if (is.name(expr)) {
            expr
        } else if (! is.call(expr) || expr[[1L]] != '$') {
            NULL
        } else {
            Recall(expr[[2L]])
        }
    }

    top_module = as.character(leftmost_name(topic))

    length(top_module) == 1L &&
        exists(top_module, parent) &&
        inherits(get(top_module, parent), 'mod$mod')
}

#' @usage
#' # ?module$function
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
        eval.parent(call('module_help', topic))
    } else {
        delegate = if ('devtools_shims' %in% search()) {
            get('?', pos = 'devtools_shims')
        } else {
            utils::`?`
        }
        eval.parent(`[[<-`(match.call(), 1L, delegate))
    }
}

#' @usage
#' # help(module$function)
#' @inheritParams utils::help
#' @export
#' @examples
#' \dontrun{
#' help(mod$func)
#' }
help = function (topic, ...) {
    topic = substitute(topic)
    delegate = if (
        ! missing(topic) && is_module_help_topic(topic, parent.frame())
    ) {
        module_help
    } else if ('devtools_shims' %in% search()) {
        get('help', pos = 'devtools_shims')
    } else {
        utils::help
    }
    eval.parent(`[[<-`(match.call(), 1L, delegate))
}

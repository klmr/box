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
    aliases = map(function (rd) unique(rd$get_value('alias')), rdfiles)
    names = rep(names(rdfiles), lengths(aliases))
    docs = stats::setNames(rdfiles[names], unlist(aliases))

    lapply(docs, format, wrap = FALSE)
}

#' @keywords internal
#' @rdname parse_documentation
parse_roxygen_tags = function (info, mod_ns) {
    mod_path = info$source_path
    blocks = roxygen2::parse_file(mod_path, mod_ns)
    roxygen2::roclet_process(
        roxygen2::rd_roclet(),
        blocks,
        mod_ns,
        dirname(mod_path)
    )
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

#' Helper functions for the help functionality
#'
#' \code{help_topic_leftmost_name} retrieves the leftmost name in an expression
#' passed to a \code{help()} call.
#' \code{call_help} invokes a \code{help()} call expression for a package help
#' topic, finding the first \code{help} function definition, ignoring the one
#' from this package.
#'
#' @param expr the expression that was passed to \code{help()}
#' @keywords internal
#' @rdname call_help
help_topic_leftmost_name = function (expr) {
    # For nested modules, `topic` looks like this: `a$b$c…`. We need to retrieve
    # the first part of this (`a`) to check whether it’s a module.

    if (is.name(expr)) {
        as.character(expr)
    } else if (! is.call(expr) || expr[[1L]] != quote(`$`)) {
        NULL
    } else {
        Recall(expr[[2L]])
    }
}

#' @param call the \code{help()} call expression.
#' @param caller the environment of the original \code{help()} caller
#' @keywords internal
call_help = function (call, caller) {
    # Search for `help` function in caller scope. This is intended to find the
    # first help call which is either `utils::help` or potentially from another
    # environment, such as `devtools_shims`.
    # Unfortunately during testing (and during development) the current package
    # *is* attached, so we can’t just use `get` in the global/caller’s
    # environment — it would recurse indefinitely to this package’s `help`
    # function. To fix this, we need to manually find the first hit that isn’t
    # inside this package.
    candidates = utils::getAnywhere('help')
    envs = map(environment, candidates$objs)
    valid = candidates$visible & map_lgl(is.function, candidates$objs)
    other_helps = candidates$obj[valid & ! map_lgl(identical, envs, topenv())]

    call[[1L]] = other_helps[[1L]]
    eval(call, envir = caller)
}

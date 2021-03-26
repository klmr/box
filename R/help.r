#' Display module documentation
#'
#' \code{help} displays help on a module’s objects and functions in much
#' the same way \code{\link[utils]{help}} does for package contents.
#'
#' @param topic either the fully-qualified name of the object or function to get
#'  help for, in the format \code{module$function}; or a name that was exported
#'  and attached from an imported module or package.
#' @param help_type character string specifying the output format; currently,
#'  only \code{'text'} is supported.
#' @return \code{help} is called for its side-effect when called directly from
#' the command prompt.
#' @details
#' See the vignette in \code{vignette('box', 'box')} for more information on
#' displaying help for modules.
#' @export
help = function (topic, help_type = getOption('help_type', 'text')) {
    topic = substitute(topic)
    target = help_topic_target(topic, parent.frame())
    target_mod = target[[1L]]
    subject = target[[2L]]

    if (! inherits(target_mod, 'box$mod')) {
        stop(
            dQuote(deparse(topic)), ' is not a valid module help topic',
            call. = FALSE
        )
    }

    if (subject != '.__module__.') {
        obj = if (
            exists(subject, target_mod, inherits = FALSE) &&
            ! bindingIsActive(subject, target_mod)
        ) get(subject, envir = target_mod, inherits = FALSE)

        if (inherits(obj, 'box$mod')) {
            target_mod = obj
            subject = '.__module__.'
        }
    }

    info = attr(target_mod, 'info')
    mod_name = strsplit(attr(target_mod, 'name'), ':')[[1L]][2L]

    if (inherits(info, 'box$pkg_info')) {
        help_call = if (subject == '.__module__.') {
            bquote(help(.(as.name(mod_name))))
        } else {
            bquote(help(topic = .(subject), package = .(mod_name)))
        }
        return(call_help(help_call, parent.frame()))
    }

    if (! requireNamespace('roxygen2')) {
        stop(
            sprintf('Displaying documentation requires %s installed', sQuote('roxygen2')),
            call. = FALSE
        )
    }

    mod_ns = attr(target_mod, 'namespace')
    all_docs = namespace_info(mod_ns, 'doc')

    if (is.null(all_docs)) {
        all_docs = parse_documentation(info, mod_ns)
        namespace_info(mod_ns, 'doc') = all_docs
    }

    doc = all_docs[[subject]]

    if (is.null(doc)) {
        if (subject == '.__module__.') {
            stop(
                'No documentation available for ', dQuote(mod_name),
                call. = FALSE
            )
        } else {
            stop(
                'No documentation available for ', dQuote(subject),
                ' in module ', dQuote(mod_name),
                call. = FALSE
            )
        }
    }

    display_help(doc, paste0('module:', mod_name), help_type)
}

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
    docs = patch_mod_doc(stats::setNames(rdfiles[names], unlist(aliases)))

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

#' @param docs the list of \pkg{roxygen2} documentation objects.
#' @keywords internal
#' @rdname parse_documentation
patch_mod_doc = function (docs) {
    if ('.__module__.' %in% names(docs)) {
        mod_doc = docs[['.__module__.']]
        mod_doc$sections$docType$value = 'package'
        mod_doc$sections$usage = NULL
        mod_doc$sections$format = NULL
        mod_doc$sections$name$value = 'module'
    }

    docs
}

#' Helper functions for the help functionality
#'
#' \code{help_topic_target} parses the expression being passed to the
#' \code{help} function call to find the innermost module subset expression in
#' it.
#' \code{find_env} acts similarly to \code{\link[utils]{find}}, except that it
#' looks in the current environment’s parents rather than in the global
#' environment search list, it returns only one hit (or zero), and it returns
#' the environment rather than a character string.
#' \code{call_help} invokes a \code{help()} call expression for a package help
#' topic, finding the first \code{help} function definition, ignoring the one
#' from this package.
#'
#' @param topic the unevaluated expression passed to \code{help}.
#' @param caller the environment from which \code{help} was called.
#' @return \code{help_topic_target} returns a list of two elements containing
#' the innermost module of the \code{help} call, as well as the name of the
#' object that’s the subject of the \code{help} call. For \code{help(a$b$c$d)},
#' it returns \code{list(c, quote(d))}.
#' @name help-internal
#' @keywords internal
help_topic_target = function (topic, caller) {
    inner_mod = function (mod, expr) {
        name = if (is.name(expr)) {
            as.character(expr)
        } else if (is.call(expr) && identical(expr[[1L]], quote(`$`))) {
            mod = Recall(mod, expr[[2L]])
            as.character(expr[[3L]])
        } else {
            stop(
                dQuote(deparse(topic)), ' is not a valid module help topic',
                call. = FALSE
            )
        }
        get(name, envir = mod)
    }

    if (is.name(topic)) {
        obj = inner_mod(caller, topic)

        if (inherits(obj, 'box$mod')) {
            list(obj, '.__module__.')
        } else {
            name = as.character(topic)
            list(find_env(name, caller), name)
        }
    } else {
        list(inner_mod(caller, topic[[2L]]), as.character(topic[[3L]]))
    }
}

#' @param name the name to look for.
#' @name help-internal
#' @keywords internal
find_env = function (name, caller) {
    while (! identical(caller, emptyenv())) {
        if (exists(name, envir = caller, inherits = FALSE)) return(caller)
        caller = parent.env(caller)
    }
    NULL
}

#' @param call the patched \code{help} call expression.
#' @name help-internal
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

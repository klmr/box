parse_documentation = function (module) {
    module_path = module_path(module)
    parsed = list(env = module,
                  blocks = roxygen2:::parse_file(module_path, module))
    roclet = roxygen2::rd_roclet()
    rdfiles = roxygen2:::roc_process(roclet, parsed, dirname(module_path))

    # Due to aliases, documentation entries may have more than one name.
    # Duplicate the relevant documentation entries to get around this.
    # Unfortunately this makes the relevant code ~7x longer.
    aliases = lapply(rdfiles, function (rd) unique(rd[[1]]$alias$values))
    doc_for_name = function (name, aliases)
        sapply(aliases, function (.) rdfiles[[name]], simplify = FALSE)
    docs = mapply(doc_for_name, names(aliases), aliases, SIMPLIFY = FALSE)
    formatted = lapply(unlist(docs, recursive = FALSE, use.names = FALSE),
                       roxygen2:::format.rd_file, wrap = FALSE)
    setNames(formatted, unlist(lapply(docs, names)))
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
    if (help_type != 'text')
        warning('Only help_type == ', sQuote('text'), ' supported for now.')

    topic = substitute(topic)

    if (! is_module_help_topic(topic, parent.frame()))
        stop(sQuote(deparse(topic)), ' is not a valid module help topic',
             call. = FALSE)

    module = get(as.character(topic[[2]]), parent.frame())
    module_name = module_name(module)
    object = as.character(topic[[3]])

    doc = attr(module, 'doc')[[object]]
    if (is.null(doc))
        stop('No documentation available for ', sQuote(object),
             ' in module ', sQuote(module_name), call. = FALSE)

    rd = tools::parse_Rd(textConnection(doc))

    # Taken from utils:::print.help_files_with_topic
    temp = tools::Rd2txt(rd, out = tempfile('Rtxt'), package = module_name)

    # Patch header line.
    doc_text = readLines(temp)
    doc_text[1] = sub('package:', ' module:', doc_text[1])
    writeLines(doc_text, temp)

    file.show(temp,
              title = gettextf('R Help on %s', sQuote(as.character(topic))),
              delete.file = TRUE)
}

is_module_help_topic = function (topic, parent)
    is.call(topic) && topic[[1]] == '$' &&
    exists(as.character(topic[[2]]), parent) &&
    ! is.null(module_name(get(as.character(topic[[2]]), parent)))

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
    if (missing(e2) && is_module_help_topic(topic, parent.frame()))
        eval(call('module_help', topic), envir = parent.frame())
    else
        eval(`[[<-`(match.call(), 1, utils::`?`), envir = parent.frame())
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
    delegate = if (is_module_help_topic(topic, parent.frame()))
        module_help
    else
        utils::help
    eval(`[[<-`(match.call(), 1, delegate), envir = parent.frame())
}

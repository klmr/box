parse_documentation = function (module) {
    module_path = module_path(module)
    parsed = list(env = module,
                  blocks = roxygen2:::parse_file(module_path, module))
    roclet = roxygen2:::rd_roclet()
    rdfiles = roxygen2:::roc_process(roclet, parsed, dirname(module_path))
    rdcontents = lapply(rdfiles, roxygen2:::format.rd_file, wrap = FALSE)
    setNames(rdcontents, sub('\\.Rd$', '', names(rdcontents)))
}

module_help = function (topic, verbose = getOption('verbose'),
                        help_type = getOption('help_type', 'text')) {
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

`?` = function (e1, e2) {
    topic = substitute(e1)
    if (missing(e2) && is_module_help_topic(topic, parent.frame()))
        eval(call('module_help', topic))
    else
        eval(`[[<-`(match.call(), 1, utils::`?`))
}

help = function (topic, ...) {
    topic = substitute(topic)
    delegate = if (is_module_help_topic(topic, parent.frame()))
        module_help
    else
        utils::help
    eval(`[[<-`(match.call(), 1, delegate))
}

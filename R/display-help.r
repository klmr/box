help_format = function (format) {
    structure(list(), class = c(paste0(format, '_help_format'), 'help_format'))
}

compile_help = function (x, rd) UseMethod('compile_help')

patch_topic_name = function(x, file, topic) UseMethod('patch_topic_name')

display_help_file = function (x, file, topic) UseMethod('display_help_file')

mock_package_name = '\1PKG\1'

compile_help.text_help_format = function (x, rd) {
    tools::Rd2txt(rd, out = tempfile('Rtxt'), package = mock_package_name)
}

compile_help.html_help_format = function (x, rd) {
    tools::Rd2HTML(rd, out = tempfile('Rtxt'), package = c(mock_package_name, NA_character_))
}

patch_topic_name.text_help_format = function (x, file, topic) {
    doc_text = readLines(file)
    old_topic = paste0('package:', mock_package_name)
    padded_old_topic = sprintf('%-*s', nchar(topic), old_topic)
    padded_new_topic = sprintf('%-*s', nchar(old_topic), topic)
    doc_text[1L] = sub(padded_old_topic, padded_new_topic, doc_text[1L])
    writeLines(doc_text, file)
}

patch_topic_name.html_help_format = function (x, file, topic) {
    from = c('&', '<', '>', '"')
    to = c('&amp;', '&lt;', '&gt;', '&quot;')
    replace = data.frame(rbind(from, to))
    topic = Reduce(function (x, r) gsub(r[1L], r[2L], x), replace, topic)
    doc_text = readLines(file)
    doc_text = gsub(mock_package_name, topic, doc_text)
    writeLines(doc_text, file)
}

display_help_file.text_help_format = function (x, file, topic) {
    file.show(
        file, title = gettextf('R Help on %s', dQuote(topic)),
        delete.file = TRUE
    )
}

display_help_file.html_help_format = function (x, file, topic) {
    topic = sanitize_path(topic)
    port = tools::startDynamicHelp(NA)
    html_path = file.path(tempdir(), sprintf('.R/doc/html/%s.html', topic))
    dir.create(dirname(html_path), recursive = TRUE, showWarnings = FALSE)
    on.exit(unlink(file))
    file.copy(file, html_path, overwrite = TRUE)
    utils::browseURL(sprintf('http://127.0.0.1:%s/doc/html/%s.html', port, topic))
}

display_help = function (help_text, title, format = c('text', 'html')) {
    format = help_format(match.arg(format))
    rd = tools::parse_Rd(textConnection(help_text))
    tempfile = compile_help(format, rd)
    patch_topic_name(format, tempfile, title)
    display_help_file(format, tempfile, title)
}

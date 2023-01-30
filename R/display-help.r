help_format = function (format, mod_name, subject) {
    structure(
        list(
            mod = mod_name,
            subject = subject,
            slug = paste0(sanitize_path_fragment(mod_name), '-', subject)
        ),
        class = c(paste0(format, '_help_format'), 'help_format')
    )
}

topics2filename = function (x) {
    gsub('%', '+', utils::URLencode(x, reserved = TRUE))
}

compile_help = function (x, rd) UseMethod('compile_help')

patch_topic_name = function(x, file) UseMethod('patch_topic_name')

display_help_file = function (x, file) UseMethod('display_help_file')

mock_package_name = '\1PKG\1'

compile_help.text_help_format = function (x, rd) {
    tools::Rd2txt(rd, out = tempfile('Rtxt'), package = mock_package_name)
}

compile_help.html_help_format = function (x, rd) {
    tools::startDynamicHelp(NA)
    # `tools:::createRedirects` creates redirects in ../help/, relative to the
    # file name, so that’s the directory name we use.
    html_path = file.path(tempdir(), fmt('.R/doc/html/help/{x$slug}.html'))
    html_dir = dirname(html_path)
    dir.create(html_dir, recursive = TRUE, showWarnings = FALSE)

    # Remove the redirects if they exist to prevent unimportant warnings from R
    # about overriding existing files …
    aliases = rd[vapply(rd, attr, character(1L), 'Rd_tag') == '\\alias']
    for (alias in topics2filename(unique(trimws(vapply(aliases, `[[`, character(1L), 1L))))) {
        unlink(file.path(html_dir, paste0(alias, '.html')), force = TRUE)
    }

    tools::Rd2HTML(rd, out = html_path, package = c(mock_package_name, NA_character_))
}

patch_topic_name.text_help_format = function (x, file) {
    doc_text = readLines(file)
    old_mod = paste0('package:', mock_package_name)
    padded_old_mod = sprintf('%-*s', nchar(x$mod), old_mod)
    padded_new_mod = sprintf('%-*s', nchar(old_mod), mod)
    doc_text[1L] = sub(padded_old_mo, padded_new_mod, doc_text[1L])
    writeLines(doc_text, file)
}

patch_topic_name.html_help_format = function (x, file) {
    doc_text = readLines(file)
    writeLines(gsub(mock_package_name, html_escape(x$mod), doc_text), file)
}

display_help_file.text_help_format = function (x, file) {
    file.show(
        file, title = gettextf('R Help on %s', dQuote(paste0(x$mod, '$', x$subject))),
        delete.file = TRUE
    )
}

display_help_file.html_help_format = function (x, file) {
    port = tools::startDynamicHelp(NA)
    utils::browseURL(fmt('http://127.0.0.1:{port}/doc/html/help/{x$slug}.html'))
}

display_help = function (help_text, mod_name, subject, format = c('text', 'html')) {
    format = help_format(match.arg(format), mod_name, subject)
    con = textConnection(help_text)
    on.exit(close(con))
    rd = tools::parse_Rd(con)
    tempfile = compile_help(format, rd)
    patch_topic_name(format, tempfile)
    display_help_file(format, tempfile)
}

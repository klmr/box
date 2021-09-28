source_file = function (path, language) {
    if (missing(language) || is.null(language)) {
        language = regmatches(path, regexpr('[^.]*$', path))
    }
    code = paste(readLines(path), collapse = '\n')
    sprintf('```%s\n%s\n```', language, code)
}

.on_load = function (ns) {
    knitr::knit_hooks$set(file = function (before, options, envir) {
        if (! before) {
            source_file(options$file, options$lang)
        }
    })
}

box::export()

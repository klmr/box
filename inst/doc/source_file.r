source_file = function (path, language) {
    if (missing(language) || is.null(language)) {
        language = regmatches(path, regexpr('[^.]*$', path))
    }
    code = paste(readLines(path), collapse = '\n')
    sprintf('```%s\n%s\n```', language, code)
}

knitr::knit_hooks$set(file = function (before, options, envir) {
    if (! before) {
        source_file(options$file, options$lang)
    }
})

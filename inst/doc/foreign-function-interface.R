## ----include=FALSE-------------------------------------------------------
options(import.path = 'inst/demo')

source_file = function (path, language) {
    if (missing(language) || is.null(language))
        language = regmatches(path, regexpr('[^.]*$', path))
    code = paste(readLines(path), collapse = '\n')
    sprintf('```%s\n%s\n```', language, code)
}

knitr::knit_hooks$set(file = function (before, options, envir) {
    if (! before) {
        # Necessary because this file is built both as vignette and
        # independent, and this happens from different working directories.
        path_prefix = if (grepl('vignettes$', getwd())) '.' else 'vignettes'
        source_file(file.path(path_prefix, options$file), options$lang)
    }
})

devtools::load_all()

## ----file='rcpp/__init__.r'----------------------------------------------

## ----file='rcpp/convolve.cpp'--------------------------------------------

## ------------------------------------------------------------------------
rcpp = import('rcpp')
ls(rcpp)
rcpp$convolve(1 : 3, 1 : 5)

## ----echo=FALSE----------------------------------------------------------
import('rcpp/__install__')

## ----file='rcpp/compiled.r'----------------------------------------------

## ------------------------------------------------------------------------
compiled = import('rcpp/compiled')
compiled$convolve(1 : 3, 1 : 5)


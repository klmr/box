## ----include=FALSE-------------------------------------------------------
rm(list = ls())

local({
    source_file = function (path, language) {
        if (missing(language) || is.null(language))
            language = regmatches(path, regexpr('[^.]*$', path))
        code = paste(readLines(path), collapse = '\n')
        sprintf('```%s\n%s\n```', language, code)
    }

    knitr::knit_hooks$set(file = function (before, options, envir)
        if (! before) {
            # Necessary because this file is built both as vignette and
            # independent, and this happens from different working directories.
            path_prefix = if (grepl('vignettes$', getwd())) '.' else 'vignettes'
            source_file(file.path(path_prefix, options$file), options$lang)
        }
    )
})

library(modules, quietly = TRUE, warn.conflicts = FALSE)

## ------------------------------------------------------------------------
seq = import('utils/seq')
ls()

## ------------------------------------------------------------------------
ls(seq)

## ----eval=FALSE----------------------------------------------------------
#  ?seq$seq

## ------------------------------------------------------------------------
s = seq$seq(c(foo = 'GATTACAGATCAGCTCAGCACCTAGCACTATCAGCAAC',
              bar = 'CATAGCAACTGACATCACAGCG'))
s

## ------------------------------------------------------------------------
seq$print.seq

## ------------------------------------------------------------------------
# We can unload loaded modules that we assigned to an identifier:
unload(seq)

options(import.path = 'utils')
import('seq', attach = TRUE)

## ------------------------------------------------------------------------
search()

## ------------------------------------------------------------------------
detach('module:seq') # Name is optional
local({
    import('seq', attach = TRUE)
    table('GATTACA')
})

## ------------------------------------------------------------------------
search()
table('GATTACA')

## ----file='utils/__init__.r'---------------------------------------------

## ------------------------------------------------------------------------
options(import.path = NULL) # Reset search path
utils = import('utils')
ls(utils)
ls(utils$seq)
utils$seq$revcomp('CAT')

## ----eval=FALSE----------------------------------------------------------
#  export_submodule('./seq')

## ----file='info.r'-------------------------------------------------------

## ------------------------------------------------------------------------
info = import('info')

## ------------------------------------------------------------------------
import('info')

## ------------------------------------------------------------------------
reload(info)


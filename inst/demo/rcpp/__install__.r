# Helper functions.

rootname = function (file, ext = '')
    paste0(sub('\\.[^.]*$', '', file), '.', ext)

rxescape = function (str)
    gsub('([.?*+^$()\\{\\}|-]|\\[|\\])', '\\\\\\1', str)

# C++ source; could potentially be more than one file.

file = 'convolve.cpp'

# The following uses Rcpp to compile (and later, load) the code. This isn’t
# necessary, but it helps quite a bit. Ideally this should be generalisable
# though: while a dependency on Rcpp is fine, it’s not acceptable to limit
# external language support to C++.

library(Rcpp)
context = .Call('sourceCppContext', PACKAGE = 'Rcpp', file, NULL, TRUE,
                .Platform)

# Compile the code
local({
    cmd = sprintf('%s/R CMD SHLIB -o %s %s',
                  R.home('bin'),
                  shQuote(context$dynlibFilename),
                  shQuote(context$cppSourceFilename))

    curdir = getwd()
    env = as.list(vapply(c('PKG_CPPFLAGS', 'PKG_LIBS'), Sys.getenv, ''))

    on.exit({
        setwd(curdir)
        Rcpp:::.restoreEnvironment(env)
    })

    setwd(context$buildDirectory)
    Sys.setenv(PKG_CPPFLAGS = Rcpp:::RcppCxxFlags())
    Sys.setenv(PKG_LIBS = Rcpp:::RcppLdFlags())
    system(cmd)
})

patch_r_binding = function () {
    source_file = file.path(context$buildDirectory, context$rSourceFile)
    source = readLines(source_file)
    source = gsub(rxescape(context$dynlibPath), context$dynlibFilename, source)
    writeLines(source, context$rSourceFile)
}

# Copy compiled sources and R wrapper code to module directory.
context$dynlibFilename = normalizePath(file.path(getwd(), rootname(file, 'so')))
file.copy(context$dynlibPath, context$dynlibFilename)
patch_r_binding()
# Make compiled module meta information available to module.
save(context, file = rootname(file, 'rdata'))

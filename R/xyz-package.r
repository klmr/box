#' An alternative module system for R
#'
#' Use \code{xyz::use(prefix/mod)} to import a module, or \code{xyz::use(pkg)}
#' to import a package. Fully qualified names are supported for nested modules,
#' reminiscent of module systems in many other modern languages.
#'
#' @section Using modules:
#'
#' \itemize{
#'  \item \code{\link{use}}
#' }
#'
#' @section Writing modules:
#'
#' Infrastructure and utility functions that are mainly used inside modules.
#'
#' \itemize{
#'  \item \code{\link{file}}
#'  \item \code{\link{name}}
#'  \item \code{\link{register_S3_method}}
#'  \item \code{\link{.on_load}}
#' }
#'
#' @section Interactive use:
#'
#' Functions for use in interactive sessions and for testing.
#'
#' \itemize{
#'  \item \code{\link{help}}
#'  \item \code{\link{reload}}
#'  \item \code{\link{set_script_path}}
#'  \item \code{\link{unload}}
#' }
#'
#' @name xyz
#' @docType package
#' @importFrom stats setNames
#' @importFrom utils lsf.str
'_PACKAGE'

.onAttach = function (libname, pkgname) {
    if (isNamespaceLoaded('devtools')) {
        is_devtools_ns = function (x) identical(x, getNamespace('devtools'))
        called_from_devtools = length(Filter(is_devtools_ns, lapply(sys.frames(), topenv))) != 0L
        if (called_from_devtools) return()
    }
    if (isNamespaceLoaded('pkgdown')) {
        is_pkgdown_ns = function (x) identical(x, getNamespace('pkgdown'))
        called_from_pkgdown = length(Filter(is_pkgdown_ns, lapply(sys.frames(), topenv))) != 0L
        if (called_from_pkgdown) return()
    }
    if (Sys.getenv('R_INSTALL_PKG') != '') return()
    if (Sys.getenv('_R_CHECK_PACKAGE_NAME_') != '') return()
    if (Sys.getenv('R_TESTS', unset = '.') == '') return()

    template = paste0(
        'The %s package is not supposed to be attached.\n\n',
        'Please consult the user guide via %s.'
    )
    help = sprintf('`vignette(\'basic-usage\', package = \'%s\')`', pkgname)
    cond = structure(
        list(message = sprintf(template, shQuote(pkgname), help), call = NULL),
        class = c('xyz_attach_error', 'error', 'condition')
    )
    stop(cond)
}

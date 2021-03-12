#' An alternative module system for R
#'
#' Use \code{box::use(prefix/mod)} to import a module, or \code{box::use(pkg)}
#' to import a package. Fully qualified names are supported for nested modules,
#' reminiscent of module systems in many other modern languages.
#'
#' @section Using modules & packages:
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
#'  \item \link{mod-hooks}
#' }
#'
#' @section Interactive use:
#'
#' Functions for use in interactive sessions and for testing.
#'
#' \itemize{
#'  \item \code{\link{help}}
#'  \item \code{\link{unload}}, \code{\link{reload}}
#'  \item \code{\link{set_script_path}}
#' }
#'
#' @useDynLib box, .registration = TRUE
#' @name box
#' @docType package
'_PACKAGE'

called_from_devtools = function () {
    if (isNamespaceLoaded('devtools')) {
        is_devtools_ns = function (x) identical(x, getNamespace('devtools'))
        length(Filter(is_devtools_ns, lapply(sys.frames(), topenv))) != 0L
    } else {
        FALSE
    }
}

called_from_pkgdown = function () {
    if (isNamespaceLoaded('pkgdown')) {
        is_pkgdown_ns = function (x) identical(x, getNamespace('pkgdown'))
        length(Filter(is_pkgdown_ns, lapply(sys.frames(), topenv))) != 0L
    } else {
        FALSE
    }
}

called_from_ci = function () {
    any(Sys.getenv(c('R_INSTALL_PKG', '_R_CHECK_PACKAGE_NAME_', 'R_TESTS')) != '')
}

called_from_example = function () {
    utils_ns = getNamespace('utils')
    example = quote(example)
    for (frame in seq_along(sys.nframe())) {
        call = sys.call(frame)
        if (identical(call[[1L]], example) && identical(topenv(sys.frame(frame)), utils_ns)) {
            return(TRUE)
        }
    }
    FALSE
}

.onAttach = function (libname, pkgname) {
    # Do not permit attaching ‘box’, except during build/check/CI.
    if (
        called_from_devtools() ||
        called_from_pkgdown() ||
        called_from_ci() ||
        # `utils::example` also attaches the package.
        called_from_example()
    ) return()

    template = paste0(
        'The %s package is not supposed to be attached.\n\n',
        'Please consult the user guide at %s.'
    )
    help = sprintf('`vignette(\'%s\', package = \'%s\')`', pkgname, pkgname)
    cond = structure(
        list(message = sprintf(template, shQuote(pkgname), help), call = NULL),
        class = c('box_attach_error', 'error', 'condition')
    )
    stop(cond)
}

.onUnload = function (libpath) {
    eapply(loaded_mods, function (mod_ns) {
        call_hook(mod_ns, '.on_unload', mod_ns)
    })
}

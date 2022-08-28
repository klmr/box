#' An alternative module system for R
#'
#' Use \code{box::use(prefix/mod)} to import a module, or \code{box::use(pkg)}
#' to import a package. Fully qualified names are supported for nested modules,
#' reminiscent of module systems in many other modern languages.
#'
#' @section Using modules & packages:
#'
#' \itemize{
#'  \item \code{\link[=use]{box::use}}
#' }
#'
#' @section Writing modules:
#'
#' Infrastructure and utility functions that are mainly used inside modules.
#'
#' \itemize{
#   \item \code{\link[=export]{box::export}}
#'  \item \code{\link[=file]{box::file}}
#'  \item \code{\link[=name]{box::name}}
#'  \item \code{\link[=register_S3_method]{box::register_S3_method}}
#'  \item \link{mod-hooks}
#' }
#'
#' @section Interactive use:
#'
#' Functions for use in interactive sessions and for testing.
#'
#' \itemize{
#'  \item \code{\link[=help]{box::help}}
#'  \item \code{\link[=unload]{box::unload}},
#'      \code{\link[=reload]{box::reload}},
#'      \code{\link[=unload]{box::purge_cache}}
#'  \item \code{\link[=set_script_path]{box::set_script_path}}
#'  \item \code{\link[=script_path]{box::script_path}},
#'      \code{\link[=script_path]{box::set_script_path}}
#' }
#'
#' @useDynLib box, .registration = TRUE
#' @name box
#' @docType package
#' @keywords internal
'_PACKAGE'

.onLoad = function (libname, pkgname) {
    assign(
        'system_mod_path',
        system.file('mod', package = 'box'),
        envir = topenv()
    )

    set_import_env_parent()
}

.onUnload = function (libpath) {
    purge_cache()
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

    is_bad_call = function (call) {
        as.character(call[[1L]]) %in% c('library', 'require')
    }

    # `unname` prevents the name from being displayed as `c(name = "box")`.
    pkgname = unname(pkgname)
    # Deparsed to silence spurious `R CMD check` warning.
    default = call('library', as.name(pkgname))
    bad_call = Filter(is_bad_call, sys.calls())[1L][[1L]] %||% default
    throw(
        'the {pkgname;\'} package is not supposed to be attached!\n\n',
        'Please consult the user guide at `{vignette}`.',
        vignette = call('vignette', pkgname, package = pkgname),
        call = bad_call,
        subclass = 'box_attach_error'
    )
}

called_from_devtools = function () {
    isNamespaceLoaded('devtools') &&
    ! nzchar(Sys.getenv('R_BOX_TEST_ALLOW_DEVTOOLS')) && {
        is_devtools_ns = function (x) identical(x, getNamespace('devtools'))
        any(map_lgl(is_devtools_ns, lapply(sys.frames(), topenv)))
    }
}

called_from_pkgdown = function () {
    isNamespaceLoaded('pkgdown') && {
        is_pkgdown_ns = function (x) identical(x, getNamespace('pkgdown'))
        any(map_lgl(is_pkgdown_ns, lapply(sys.frames(), topenv)))
    }
}

called_from_ci = function () {
    any(Sys.getenv(c('R_INSTALL_PKG', '_R_CHECK_PACKAGE_NAME_', 'R_TESTS')) != '')
}

called_from_example = function () {
    utils_ns = getNamespace('utils')
    example = quote(example)
    frames = sys.frame()
    # N.B.: This only handles direct, unqualified calls, i.e.
    #   example(…)
    # it fails with other forms, such as
    #   utils::example(…)
    #   get('example')(…)
    # etc.
    is_example_call = function (i)
        identical(sys.call(i)[[1L]], example) &&
            identical(topenv(sys.frame(i)), utils_ns)
    any(map_lgl(is_example_call, seq_len(sys.nframe())))
}

import_env_parent = NULL

# Separate function for unit testing.
set_import_env_parent = function () {
    utils::assignInMyNamespace(
        'import_env_parent',
        if (getOption('box.warn.legacy', TRUE)) {
            legacy_intercept_env
        } else {
            baseenv()
        }
    )
}

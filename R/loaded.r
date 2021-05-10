#' Environment of loaded modules
#'
#' Each module is stored as an environment inside \code{loaded_mods} with the
#' module’s code location path as its identifier. The path rather than the
#' module name is used because module names are not unique: two modules called
#' \code{a} can exist nested inside modules \code{b} and \code{c}, respectively.
#' Yet these may be loaded at the same time and need to be distinguished.
#'
#' \code{is_mod_loaded} tests whether a module is already loaded.
#'
#' \code{register_mod} caches a module namespace and marks the module as loaded.
#'
#' \code{deregister_mod} removes a module namespace from the cache, unloading
#' the module from memory.
#'
#' \code{loaded_mod} retrieves a loaded module namespace given its info.
#'
#' \code{is_mod_still_loading} tests whether a module is still being loaded.
#'
#' \code{mod_loading_finished} signals that a module has been completely loaded.
#'
#' @format \code{loaded_mods} is an environment of the loaded module and package
#' namespaces.
#'
#' @keywords internal
#' @name loaded
loaded_mods = new.env(parent = emptyenv())

#' @param info the mod info of a module
#' @rdname loaded
is_mod_loaded = function (info) {
    info$source_path %in% names(loaded_mods)
}

#' @param mod_ns module namespace environment
#' @rdname loaded
register_mod = function (info, mod_ns) {
    loaded_mods[[info$source_path]] = mod_ns
    attr(loaded_mods[[info$source_path]], 'loading') = TRUE
}

#' @rdname loaded
deregister_mod = function (info) {
    rm(list = info$source_path, envir = loaded_mods)
}

#' @rdname loaded
loaded_mod = function (info) {
    loaded_mods[[info$source_path]]
}

#' @note \code{is_mod_still_loading} and \code{mod_loading_finished} are used to
#' break cycles during the loading of modules with cyclic dependencies.
#' @rdname loaded
is_mod_still_loading = function (info) {
    # pkg_info has no `source_path` but already finished loading anyway.
    ! is.null(info$source_path) && attr(loaded_mods[[info$source_path]], 'loading')
}

#' @rdname loaded
mod_loading_finished = function (info, mod_ns) {
    attr(loaded_mods[[info$source_path]], 'loading') = FALSE
}

#' Get a module’s path
#'
#' The following functions retrieve information about the path of the directory
#' that a module or script is running in.
#' @param mod a module environment or namespace
#' @return \code{path} returns a character string containing the module’s full
#' path.
#' @keywords internal
path = function (mod) {
    UseMethod('path')
}

#' @export
`path.box$mod` = function (mod) {
    attr(mod, 'info')$source_path
}

#' @export
`path.box$ns` = function (mod) {
    namespace_info(mod, 'info')$source_path
}

#' @param mod a module environment or namespace.
#' @return \code{base_path} returns a character string containing the module’s
#' base directory, or the current working directory if not invoked on a module.
#' @rdname path
base_path = function (mod) {
    path = tryCatch(dirname(path(mod)), error = function (e) script_path())
    normalizePath(path, winslash = '/')
}

#' Set the base path of the script
#'
#' @param path character string containing the relative or absolute path to the
#' currently executing R code file, or \code{NULL} to reset the path.
#' @return \code{box::set_script_path} returns the previously set script path,
#' or \code{NULL} if none was explicitly set.
#'
#' @details
#' \pkg{box} needs to know the base path of the topmost calling R context (i.e.
#' the script) to find relative import locations. In most cases, \code{box} can
#' figure the path out automatically. However, in some cases third-party
#' packages load code in a way in which \pkg{box} cannot find the correct path
#' of the script any more. \code{set_script_path} can be used in these cases to
#' set the path of the currently executing R script manually.
#' @export
set_script_path = function (path = NULL) {
    old_path = script_path_env$value
    if (is.null(path)) {
        script_path_env$value = NULL
    } else {
        script_path_env$value = dirname(path)
    }
    invisible(old_path)
}

script_path_env = new.env(parent = emptyenv())

#' @return \code{script_path} returns a character string that contains the
#' directory in which the calling R code is run. See \sQuote{Details}.
#' @details
#' \code{script_path} takes a best guess at a script’s path, since R does not
#' provide a sure-fire way for determining the path of the currently executing
#' code. The following calling situations are covered:
#'
#' \enumerate{
#'  \item Path explicitly set via \code{set_script_path}
#'  \item Path of a running document/application (\pkg{knitr}, \pkg{Shiny})
#'  \item Path of unit test cases (\pkg{testthat})
#'  \item Path of the currently opened source code file in RStudio
#'  \item Code invoked as \command{Rscript script.r}
#'  \item Code invoked as \command{R CMD BATCH script.r}
#'  \item Code invoked as \command{R -f script.r}
#'  \item Script run interactively (use \code{getwd()})
#' }
#' @rdname path
script_path = function () {
    for (test in path_tests) {
        path = test()
        if (! is.null(path)) {
            # Don’t cache result, since it might change suddenly, due to knitr
            # or Shiny running in the same proces.
            return(path)
        }
    }
    stop('Unreachable code')
}

#' @return \code{explicit_path} returns the script path explicitly set by the
#' user, if such a path was set.
#' @rdname path
explicit_path = function () {
    if (! is.null((path = script_path_env$value))) path
}

#' @param args command line arguments passed to R; by default, the arguments of
#' the current process.
#' @return \code{r_path} returns the directory in which the current script is
#' run via \command{Rscript}, \command{R CMD BATCH} or \command{R -f}.
#' @rdname path
r_path = function (args = commandArgs()) {
    if (length((file_arg = grep('^--file=', args))) != 0L) {
        dirname(sub('--file=', '', args[file_arg]))
    } else if (length((f_arg = grep('^-f$', args))) != 0L) {
        dirname(args[f_arg + 1L])
    }
}

#' @return \code{knitr_path} returns the directory in which the currently knit
#' document is run, or \code{NULL} if not called from within a \pkg{knitr}
#' document.
#' @rdname path
knitr_path = function () {
    if (! 'knitr' %in% loadedNamespaces()) return(NULL)

    knitr_input = suppressWarnings(knitr::current_input(dir = TRUE))
    if (! is.null(knitr_input)) dirname(knitr_input)
}

#' @return \code{shiny_path} returns the directory in which a \pkg{Shiny}
#' application is running, or \code{NULL} if not called from within a
#' \pkg{Shiny} application.
#' @rdname path
shiny_path = function () {
    if ('shiny' %in% loadedNamespaces() && shiny::isRunning()) getwd()
}

#' @return \code{testthat_path} returns the directory in which \pkg{testthat}
#' code is being executed, or \code{NULL} if not called from within a
#' \pkg{testthat} test case.
#' @rdname path
testthat_path = function () {
    if (identical(Sys.getenv("TESTTHAT"), "true")) getwd()
}

#' @return \code{rstdio_path} returns the directory in which the currently
#' active RStudio script file is saved.
#' @rdname path
rstudio_path = function () {
    if (! 'rstudioapi' %in% loadedNamespaces() || ! rstudioapi::isAvailable()) return(NULL)

    document_path = rstudioapi::getActiveDocumentContext()$path
    if (! identical(document_path, '')) dirname(document_path)
}

#' @return \code{wd_path} returns the current working directory.
#' @rdname path
wd_path = function () {
    # Fallback
    getwd()
}

path_test_hooks = c('explicit', 'knitr', 'shiny', 'testthat', 'rstudio', 'r', 'wd')
path_tests = mget(paste0(path_test_hooks, '_path'))

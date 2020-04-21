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
`path.mod$mod` = function (mod) {
    attr(mod, 'info')$source_path
}

#' @export
`path.mod$ns` = function (mod) {
    namespace_info(mod, 'info')$source_path
}

#' @param mod a module environment or namespace
#' @return \code{base_path} returns a character string containing the module’s
#' base directory, or the current working directory if not invoked on a module.
#' @rdname path
base_path = function (mod) {
    path = tryCatch(dirname(path(mod)), error = function (e) script_path())
    normalizePath(path, winslash = '/')
}

#' Set the base path of the script
#'
#' @param path character string containing the relative or absolute path, or
#' \code{NULL} to reset the path
#'
#' @details
#' \emph{modules} needs to know the base path of the topmost calling R script
#' to find relative import locations. In most cases, it can figure the path out
#' automatically. However, in some cases third party packages load files in such
#' a way that \emph{modules} cannot find out the correct path of the script any
#' more. \code{set_script_path} can be used in these cases to set the script
#' path manually.
#' @export
set_script_path = function (path) {
    if (is.null(path)) {
        # Use `list = '.'` instead of `.` to work around bug in `R CMD CHECK`,
        # which thinks that `.` refers to a non-existent global symbol.
        rm(list = '.', envir = loaded_mods)
    } else {
        assign('.', dirname(path), loaded_mods)
    }
}

#' @return \code{script_path} returns a character string that contains the
#' directory in which the calling R code is run. See ‘Details’.
#' @details
#' \code{script_path} takes a best guess at a script’s path, since R does not
#' provide a sure-fire way for determining the path of the currently executing
#' code. The following calling situations are covered:
#'
#' \enumerate{
#'  \item Path explicitly set via \code{set_script_path}
#'  \item Path of a running document/application (knitr, Shiny)
#'  \item Code invoked as \code{Rscript script.r}
#'  \item Code invoked as \code{R CMD BATCH script.r}
#'  \item Script run interactively (use \code{getwd()})
#' }
#' @rdname path
script_path = function () {
    if (exists('.', envir = loaded_mods, inherits = FALSE)) {
        return(loaded_mods$.)
    }

    if (! is.null((knitr_path = knitr_path()))) return(knitr_path)

    if (! is.null((shiny_path = shiny_path()))) return(shiny_path)

    args = commandArgs()

    file_arg = grep('--file=', args)
    if (length(file_arg) != 0L) {
        return(dirname(sub('--file=', '', args[file_arg])))
    }

    f_arg = grep('-f', args)
    if (length(f_arg) != 0L) return(dirname(args[f_arg + 1L]))

    getwd()
}

#' @return \code{knitr_path} returns the directory in which the currently knit
#' document is run, or \code{NULL} if not called from within a knitr document.
#' @rdname path
knitr_path = function () {
    if (! 'knitr' %in% loadedNamespaces()) return(NULL)

    knitr_input = suppressWarnings(knitr::current_input(dir = TRUE))
    if (! is.null(knitr_input)) dirname(knitr_input)
}

#' @return \code{shiny_path} returns the directory in which a Shiny application
#' is running, or \code{NULL} if not called from within a Shiny application.
#' @rdname path
shiny_path = function () {
    if ('shiny' %in% loadedNamespaces() && shiny::isRunning()) getwd()
}

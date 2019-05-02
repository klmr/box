#' Environment of loaded modules
#'
#' Each module is stored as an environment inside \code{loaded_mods} with the
#' module’s code location path as its identifier. The path rather than the
#' module name is used because module names are not unique: two modules called
#' \code{a} can exist nested inside modules \code{b} and \code{c}, respectively.
#' Yet these may be loaded at the same time and need to be distinguished.
#' @keywords internal
#' @name loaded
loaded_mods = new.env(parent = emptyenv())

#' \code{is_mod_loaded} tests whether a module is already loaded
#' @param info the mod info of a module
#' @rdname loaded
is_mod_loaded = function (info) {
    # TODO: Use
    #   exists(info$source_path, envir = loaded_mods, inherits = FALSE)
    # instead?
    info$source_path %in% names(loaded_mods)
}

#' \code{register_mod} caches a module namespace and marks the module as loaded.
#' @param mod_ns module namespace environment
#' @rdname loaded
register_mod = function (info, mod_ns) {
    # TODO: use
    #   assign(info$source_path, mod_ns, envir = loaded_mods)
    # instead?
    loaded_mods[[info$source_path]] = mod_ns
    attr(loaded_mods[[info$source_path]], 'loading') = TRUE
}

#' \code{deregister_mod} removes a module namespace from the cache, unloading
#' the module from memory.
#' @rdname loaded
deregister_mod = function (info) {
    rm(list = info$source_path, envir = loaded_mods)
}

#' \code{loaded_mod} retrieves a loaded module namespace given its info
#' @rdname loaded
loaded_mod = function (info) {
    loaded_mods[[info$source_path]]
}

#' \code{is_mod_still_loading} tests whether a module is still being loaded.
#' @note \code{is_mod_still_loading} and \code{mod_loading_finished} are used to
#' break cycles during the loading of modules with cyclic dependencies.
#' @rdname loading
is_mod_still_loading = function (info) {
    # pkg_info has no `source_path` but already finished loading anyway.
    ! is.null(info$source_path) && attr(loaded_mods[[info$source_path]], 'loading')
}

#' \code{mod_loading_finished} signals that a module has been completely loaded.
#' @rdname loading
mod_loading_finished = function (info, mod_ns) {
    attr(loaded_mods[[info$source_path]], 'loading') = FALSE
}

#' Get a module’s path
#'
#' @param mod a module environment or namespace
#' @return A character string containing the module’s full path.
path = function (mod) {
    UseMethod('path')
}

`path.mod$mod` = function (mod) {
    attr(mod, 'info')$source_path
}

`path.mod$ns` = function (mod) {
    namespace_info(mod, 'info')$source_path
}

#' Get a module’s base directory
#'
#' @param mod a module environment or namespace
#' @return A character string containing the module’s base directory,
#'  or the current working directory if not invoked on a module.
base_path = function (mod) {
    path = tryCatch(dirname(path(mod)), error = function (e) script_path())
    normalizePath(path, winslash = '/')
}

#' Set the base path of the script.
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

#' Return an R script’s path
script_path = function () {
    # Take a best guess at a script’s path. The following calling situations are
    # covered:
    #
    # 1. Explicitly via `set_script_path` set script path
    # 2. Inside calling container (knitr, Shiny)
    # 3. Rscript script.r
    # 4. R CMD BATCH script.r
    # 5. Script run interactively (give up, use `getwd()`)

    if (exists('.', envir = loaded_mods, inherits = FALSE)) {
        return(get('.', envir = loaded_mods, inherits = FALSE))
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

knitr_path = function () {
    if (! 'knitr' %in% loadedNamespaces()) return(NULL)

    knitr_input = suppressWarnings(knitr::current_input(dir = TRUE))
    if (! is.null(knitr_input)) dirname(knitr_input)
}

shiny_path = function () {
    if ('shiny' %in% loadedNamespaces() && shiny::isRunning()) getwd()
}

#' Get a module’s name
#'
#' @param module a module environment (default: current module)
#' @return A character string containing the name of the module or \code{NULL}
#'  if called from outside a module.
#' @note A module’s name is the name of a module that it was \code{import}ed
#' with. If the same module is subsequently imported using another qualifie
#' name (from within the same package, say, and hence truncated), the module
#' names of the two module instances may differ, even though the same copy of
#' the byte code is used.
#' This function approximates Python’s magic variable \code{__name__}, and can
#' be used similarly to test whether a module was loaded via \code{import} or
#' invoked directly.
#' @examples
#' \dontrun{
#' message('This code is always executed.\n')
#'
#' if (is.null(module_name())) {
#'     message('This code is only executed when the module is run
#'              as stand-alone code via Rscript or R CMD BATCH.\n')
#' }
#' }
#' @export
module_name = function (module = parent.frame()) {
    name = try(module_attr(module, 'name'), silent = TRUE)
    if (inherits(name, 'try-error'))
        NULL
    else
        strsplit(name, ':', fixed = TRUE)[[1L]][2L]
}

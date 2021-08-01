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

#' Unload or reload a given module
#'
#' Unload a given module or reload it from its source.
#' @param mod the module reference to be unloaded or reloaded
#'
#' @details
#' Unloading a module causes it to be purged from the internal cache such that
#' the next subsequent \code{xyz::use} declaration will reload the module from
#' its source. \code{reload} is a shortcut for unloading a module and calling
#' \code{xyz::use} in the same scope with the same parameters as the
#' \code{xyz::use} call that originally loaded the current module instance.
#'
#' @note Any other references to the loaded modules remain unchanged, and will
#' still work. Unloading and reloading modules is primarily useful for testing
#' during development, and should not be used in production code.
#'
#' \code{unload} and \code{reload} come with a few restrictions. \code{unload}
#' attempts to detach names attached by the corresponding \code{xyz::use} call.
#' \code{reload} attempts to re-attach these same names. This only works if the
#' corresponding \code{xyz::use} declaration is located in the same scope.
#'
#' \code{reload} will re-execute the \code{.on_load} hook of the module.
#' @seealso \code{\link{use}}, \link{mod-hooks}
#' @export
unload = function (mod) {
    stopifnot(inherits(mod, 'xyz$mod'))
    stopifnot(is.name(substitute(mod)))
    deregister_mod(attr(mod, 'info'))
    attached = attr(mod, 'attached')
    if (! is.null(attached)) {
        if (identical(attached, '')) {
            caller = parent.frame()
            parent.env(caller) = parent.env(parent.env(caller))
        } else {
            attached_pos = match(attached, search())
            if (! is.na(attached_pos)) {
                detach(attached, character.only = TRUE)
            }
        }
    }
    # Unset the mod reference in its scope, i.e. the caller’s environment or
    # some parent thereof.
    mod_ref = as.character(substitute(mod))
    rm(list = mod_ref, envir = parent.frame(), inherits = TRUE)
}

#' @name unload
#' @export
reload = function (mod) {
    stopifnot(inherits(mod, 'xyz$mod'))
    stopifnot(is.name(substitute(mod)))
    caller = parent.frame()
    spec = attr(mod, 'spec')
    info = attr(mod, 'info')

    ns = loaded_mod(info)
    deregister_mod(info)
    # If loading fails, restore old module.
    on.exit(register_mod(info, ns))

    # FIXME: Update to new API
    attached = attr(mod, 'attached')
    if (! is.null(attached)) {
        if (identical(attached, '')) {
            attached_env = parent.env(caller)
            parent.env(caller) = parent.env(attached_env)
            on.exit((parent.env(caller) = attached_env), add = TRUE)
        } else {
            attached_pos = match(attached, search())
            if (! is.na(attached_pos)) {
                detach(attached, character.only = TRUE)
            }
            on.exit(
                xyz_attach(attached_env, pos = attached_pos, name = attached),
                add = TRUE
            )
        }
    }

    load_and_register(spec, info, caller)
    # Loading worked, so cancel restoring the old module.
    on.exit()
}

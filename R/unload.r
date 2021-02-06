#' Unload or reload a given module
#'
#' Unload a given module or reload it from its source.
#' @param mod the module reference to be unloaded or reloaded
#' @return \code{box::unload} and \code{box::reload} are called for their
#' side-effect. They do not return anything.
#'
#' @details
#' Unloading a module causes it to be purged from the internal cache such that
#' the next subsequent \code{box::use} declaration will reload the module from
#' its source. \code{reload} is a shortcut for unloading a module and calling
#' \code{box::use} in the same scope with the same parameters as the
#' \code{box::use} call that originally loaded the current module instance.
#'
#' @note Any other references to the loaded modules remain unchanged, and will
#' still work. Unloading and reloading modules is primarily useful for testing
#' during development, and should not be used in production code.
#'
#' \code{unload} and \code{reload} come with a few restrictions. \code{unload}
#' attempts to detach names attached by the corresponding \code{box::use} call.
#' \code{reload} attempts to re-attach these same names. This only works if the
#' corresponding \code{box::use} declaration is located in the same scope.
#'
#' \code{reload} will re-execute the \code{.on_load} hook of the module.
#' @seealso \code{\link{use}}, \link{mod-hooks}
#' @export
unload = function (mod) {
    stopifnot(is.name(substitute(mod)))
    stopifnot(inherits(mod, 'box$mod'))

    mod_ns = attr(mod, 'namespace')
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

    call_hook(mod_ns, '.on_unload', mod_ns)
    deregister_mod(attr(mod, 'info'))

    # Unset the mod reference in its scope, i.e. the caller’s environment or
    # some parent thereof.
    mod_ref = as.character(substitute(mod))
    rm(list = mod_ref, envir = parent.frame(), inherits = TRUE)
}

#' @name unload
#' @export
reload = function (mod) {
    stopifnot(is.name(substitute(mod)))
    stopifnot(inherits(mod, 'box$mod'))

    caller = parent.frame()
    spec = attr(mod, 'spec')
    info = attr(mod, 'info')
    mod_ns = attr(mod, 'namespace')
    attached = attr(mod, 'attached')

    call_hook(mod_ns, '.on_unload', mod_ns)
    deregister_mod(info)

    on.exit({
        warning(sprintf(
            'Reloading module %s failed, attempting to restore the old instance.',
            dQuote(deparse(substitute(mod)))
        ))
        register_mod(info, mod_ns)
    })

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
                box_attach(attached_env, pos = attached_pos, name = attached),
                add = TRUE
            )
        }
    }

    load_and_register(spec, info, caller)
    # Loading worked, so cancel restoring the old module.
    on.exit()
}

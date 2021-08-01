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
#' its source. \code{box::reload} unloads and reloads the specified modules and
#' all its transitive module dependencies. \code{box::reload} is \emph{not}
#' merely a shortcut for calling \code{box::unload} followed by \code{box::use},
#' because \code{box::unload} only unloads the specified module itself, not any
#' dependent modules.
#'
#' @note Any other references to the loaded modules remain unchanged, and will
#' (usually) still work. Unloading and reloading modules is primarily useful for
#' testing during development, and \emph{should not be used in production code:}
#' in particular, unloading may break other module references if the
#' \code{.on_unload} hook unloaded any binary shared libraries which are still
#' referenced.
#'
#' \code{unload} and \code{reload} come with a few restrictions. \code{unload}
#' attempts to detach names attached by the corresponding \code{box::use} call.
#' \code{reload} attempts to re-attach these same names. This only works if the
#' corresponding \code{box::use} declaration is located in the same scope.
#'
#' \code{unload} will execute the \code{.on_unload} hook of the module, if it
#' exists.
#' \code{reload} will re-execute the \code{.on_load} hook of the module and of
#' all dependent modules during loading (after executing the corresponding
#' \code{.on_unload} hooks during unloading).
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

    unload_mod(mod_ns, attr(mod, 'info'))

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

    unload_mod_recursive(mod_ns, info)

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

#' @keywords internal
unload_mod = function (mod_ns, info) {
    call_hook(mod_ns, '.on_unload', mod_ns)
    deregister_mod(info)
}

#' @keywords internal
unload_mod_recursive = function (mod_ns, info) {
    unload_mod(mod_ns, info)

    for (import in namespace_info(mod_ns, 'imports')) {
        unload_mod_recursive(import$ns, import$info)
    }
}

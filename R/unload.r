#' Unload or reload modules
#'
#' Given a module which has been previously loaded and is assigned to an alias
#' \code{mod}, \code{box::unload(mod)} unloads it; \code{box::reload(mod)}
#' unloads and reloads it from its source. \code{box::purge_cache()} marks all
#' modules as unloaded.
#' @usage \special{box::unload(mod)}
#' @param mod a module object to be unloaded or reloaded
#' @return These functions are called for their side effect. They do not return
#' anything.
#'
#' @details
#' Unloading a module causes it to be removed from the internal cache such that
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
#' These functions come with a few restrictions.
#' \code{box::unload} attempts to detach names attached by the corresponding
#' \code{box::use} call.
#' \code{box::reload} attempts to re-attach these same names. This only works if
#' the corresponding \code{box::use} declaration is located in the same scope.
#' \code{box::purge_cache} only removes the internal cache of modules, it does
#' not actually invalidate any module references or names attached from loaded
#' modules.
#'
#' \code{box::unload} will execute the \code{.on_unload} hook of the module, if
#' it exists.
#' \code{box::reload} will re-execute the \code{.on_load} hook of the module and
#' of all dependent modules during loading (after executing the corresponding
#' \code{.on_unload} hooks during unloading).
#' \code{box::purge_cache} will execute any existing \code{.on_unload} hooks in
#' all loaded modules.
#' @seealso \code{\link[=use]{box::use}}, \link[=mod-hooks]{module hooks}
#' @export
unload = function (mod) {
    modname = substitute(mod)
    expect(
        is.name(modname),
        '{"unload";"} expects a module object, got {modname;"}, ',
        'which is not a module alias variable'
    )

    mod_ref = as.character(modname)
    expect(
        exists(mod_ref, envir = parent.frame()),
        'object {mod_ref;"} not found'
    )
    expect(
        inherits(mod, 'box$mod'),
        '{"unload";"} expects a module object, got {modname;"}, ',
        'which is of type {class(mod);"} instead'
    )

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
    rm(list = mod_ref, envir = parent.frame(), inherits = TRUE)
}

#' @usage \special{box::reload(mod)}
#' @name unload
#' @export
reload = function (mod) {
    modname = substitute(mod)
    expect(
        is.name(modname),
        '{"reload";"} expects a module object, got {modname;"}, ',
        'which is not a module alias variable'
    )

    mod_ref = as.character(modname)
    expect(
        exists(mod_ref, envir = parent.frame()),
        'object {mod_ref;"} not found'
    )
    expect(
        inherits(mod, 'box$mod'),
        '{"reload";"} expects a module object, got {modname;"}, ',
        'which is of type {class(mod);"} instead'
    )

    caller = parent.frame()
    spec = attr(mod, 'spec')
    info = attr(mod, 'info')
    mod_ns = attr(mod, 'namespace')
    attached = attr(mod, 'attached')

    unload_mod_recursive(mod_ns, info)

    on.exit({
        warning(fmt('Reloading module {modname;"} failed, attempting to restore the old instance.'))
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

#' @usage \special{box::purge_cache()}
#' @name unload
#' @export
purge_cache = function () {
    eapply(loaded_mods, function (mod_ns) {
        call_hook(mod_ns, '.on_unload', mod_ns)
    }, all.names = TRUE)
    rm(list = names(loaded_mods), envir = loaded_mods)
}

#' @keywords internal
unload_mod = function (mod_ns, info) {
    call_hook(mod_ns, '.on_unload', mod_ns)
    deregister_mod(info)
}

#' @keywords internal
unload_mod_recursive = function (mod_ns, info) {
    UseMethod('unload_mod_recursive')
}

`unload_mod_recursive.box$ns` = function (mod_ns, info) {
    unload_mod(mod_ns, info)

    for (import in namespace_info(mod_ns, 'imports')) {
        unload_mod_recursive(import$ns, import$info)
    }
}

# Package namespace
unload_mod_recursive.environment = function (mod_ns, info) {}

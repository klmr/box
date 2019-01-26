#' Unload a given module
#'
#' Unset the module variable that is being passed as a parameter, and remove the
#' loaded module from cache.
#' @param mod reference to the module which should be unloaded
#' @note Any other references to the loaded modules remain unchanged, and will
#' still work. However, subsequently importing the module again will reload its
#' source files, which would not have happened without \code{mod::unload}.
#' Unloading modules is primarily useful for testing during development, and
#' should not be used in production code.
#'
#' \code{mod::unload} comes with a few restrictions. It attempts to detach
#' itself if it was previously attached. This only works if it is called in the
#' same scope as the original \code{mod::use} call, or an inherited scope.
#' @seealso \code{\link{use}}
#' @seealso \code{\link{reload}}
#' @export
unload = function (mod) {
    stopifnot(inherits(mod, 'mod$mod'))
    deregister_mod(attr(mod, 'info'))
    attached = attr(mod, 'attached')
    if (! is.null(attached) && ! is.na(match(attached, search())))
        detach(attached, character.only = TRUE)
    # Unset the mod reference in its scope, i.e. the caller’s environment or
    # some parent thereof.
    mod_ref = as.character(substitute(mod))
    rm(list = mod_ref, envir = parent.frame(), inherits = TRUE)
}

#' Reload a given module
#'
#' Remove the loaded module from the cache, forcing a reload. The newly reloaded
#' module is assigned to the module reference in the calling scope.
#' @param module reference to the module which should be unloaded
#' @note Any other references to the loaded modules remain unchanged, and will
#' still work. Reloading modules is primarily useful for testing during
#' development, and should not be used in production code.
#'
#' \code{reload} comes with a few restrictions. It attempts to re-attach itself
#' in parts or whole if it was previously attached in parts or whole. This only
#' works if it is called in the same scope as the original \code{import}.
#' @seealso \code{\link{import}}
#' @seealso \code{\link{unload}}
#' @export
reload = function (module) {
    stopifnot(inherits(module, 'module'))
    module_ref = as.character(substitute(module))

    module_ns = get_loaded_module(module_path(module))
    uncache_module(module)
    # If loading fails, restore old module.
    on.exit(cache_module(module_ns))

    attached = attr(module, 'attached')
    if (! is.null(attached)) {
        attached_pos = match(attached, search())
        if (! is.na(attached_pos)) {
            attached_env = as.environment(attached)
            detach(attached, character.only = TRUE)
            # To avoid spurious `R CMD CHECK` warning. Modules only uses
            # `attach` when explicitly prompted by the user, so the use should
            # be acceptable.
            on.exit(get('attach', .BaseNamespaceEnv, mode = 'function')
                    (attached_env, pos = attached_pos, name = attached),
                    add = TRUE)
        }
    }

    # Use `eval` to replicate the exact call being made to `import`.
    mod_env = eval.parent(attr(module, 'call'))
    # Importing worked, so cancel restoring the old module.
    on.exit()

    assign(module_ref, mod_env, envir = parent.frame(), inherits = TRUE)
}

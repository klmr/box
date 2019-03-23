#' Reload a given module
#'
#' Reload the referenced module by removing it from the module cache. The newly
#' reloaded module is assigned to the existing module reference in the calling
#' scope.
#' @param mod name of the module which should be reloaded
#' @note Any other references to the loaded modules remain unchanged, and will
#' still work. Reloading modules is primarily useful for testing during
#' development, and should not be used in production code.
#'
#' \code{reload} comes with a few restrictions. It attempts to re-attach itself
#' in parts or whole if it was previously attached in parts or whole. This only
#' works if it is called in the same scope as the original \code{mod::use}.
#' @seealso \code{\link{use}}
#' @seealso \code{\link{unload}}
#' @export
reload = function (mod) {
    stopifnot(inherits(mod, 'mod$mod'))
    stopifnot(is.name(substitute(mod)))
    caller = parent.frame()
    spec = attr(mod, 'spec')
    info = attr(mod, 'info')

    ns = loaded_mod(info)
    deregister_mod(info, ns)
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
            # To avoid spurious `R CMD CHECK` warning. Modules only uses
            # `attach` when explicitly prompted by the user, so the use should
            # be acceptable.
            on.exit(
                get('attach', .BaseNamespaceEnv, mode = 'function')
                    (attached_env, pos = attached_pos, name = attached),
                add = TRUE
            )
        }
    }

    load_and_register(spec, info, caller)
    # Loading worked, so cancel restoring the old module.
    on.exit()
}

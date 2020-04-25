#' Unload a given module
#'
#' Unset the module name that is being passed as a parameter, and remove the
#' loaded module from cache.
#' @param mod name of the module which should be unloaded
#' @note Any other references to the loaded modules remain unchanged, and will
#' still work. However, subsequently importing the module again will reload its
#' source files, which would not have happened without \code{xyz::unload}.
#' Unloading modules is primarily useful for testing during development, and
#' should not be used in production code.
#'
#' \code{xyz::unload} comes with a few restrictions. It attempts to detach
#' itself if it was previously attached. This only works if it is called in the
#' same scope as the original \code{xyz::use} call, or an inherited scope.
#' @seealso \code{\link{use}}
#' @seealso \code{\link{reload}}
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

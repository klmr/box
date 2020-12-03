#' @keywords internal
call_hook = function (ns, hook, ...) {
    hook_fn = get0(hook, ns, mode = 'function', inherits = FALSE)
    if (! is.null(hook_fn)) hook_fn(...)
}

#' Hooks for module events
#'
#' Modules can declare functions to be called when a module is first loaded,
#' every time it is used or attached, and when it is detached and unloaded.
#'
#' @param ns the module namespace environment
#'
#' @note The API for hook functions is still subject to change. In particular,
#' there might in the future be a way to subscribe to module events of other
#' modules and packages, equivalently to R package \link[base]{userhooks}.
#'
#' @details
#' For \code{.on_load}, \code{ns} is the unlocked module namespace environment.
#' This means that code in \code{.on_load} is permitted to modify the namespace
#' by adding to, replacing, or removing names from the namesapce.
#'
#' @name mod-hooks
#' @keywords utilities
#' @concept experimental
.on_load = function (ns) NULL

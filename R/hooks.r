#' @keywords internal
call_hook = function (ns, hook, ...) {
    if (namespace_info(ns, 'legacy', FALSE)) return()

    hook_fn = get0(hook, ns, mode = 'function', inherits = FALSE)
    if (! is.null(hook_fn)) hook_fn(...)
}

#' Hooks for module events
#'
#' Modules can declare functions to be called when a module is first loaded.
#'
#' @param ns the module namespace environment
#' @return Any return values of the hook functions are ignored.
#'
#' @note The API for hook functions is still subject to change. In particular,
#' there might in the future be a way to subscribe to module events of other
#' modules and packages, equivalently to R package \link[base]{userhooks}.
#'
#' @details
#' To create module hooks, modules should define a function with the specified
#' name and signature. Module hooks should \emph{not} be exported.
#'
#' When \code{.on_load} is called, the unlocked module namespace environment is
#' passed to it via its parameter \code{ns}. This means that code in
#' \code{.on_load} is permitted to modify the namespace by adding names to,
#' replacing names in, or removing names from the namespace.
#'
#' \code{.on_unload} is called when modules are unloaded. The (locked) module
#' namespace is passed as an argument. It is primarily useful to clean up
#' resources used by the module. Note that, as for packages, \code{.on_unload}
#' is \emph{not} necessarily called when R is shut down.
#'
#' \emph{Legacy modules} cannot use hooks. To use hooks, the module needs to
#' contain an export specification (if the module should not export any names,
#' specify an explicit, empty export list via
#' \code{\link[=export]{box::export()}}.
#'
#' @name mod-hooks
#' @keywords utilities
#' @concept experimental
.on_load = function (ns) NULL

#' @name mod-hooks
.on_unload = function (ns) NULL

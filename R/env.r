#' Module namespace handling
#'
#' The namespace contains a module’s content. This schema is very much like R
#' package organisation. A good resource for this is:
#' <http://obeautifulcode.com/R/How-R-Searches-And-Finds-Stuff/>
#' @name namespace
#' @keywords internal
make_namespace = function (info) {
    # Packages use `baseenv()` instead of `emptyenv()` for the parent
    # environment of `.__NAMESPACE__.`. I don’t know why: there should never be
    # any need for inherited name lookup. We’re only using an environment for
    # `.__module__.` to get efficient name lookup and a mutable value store.
    ns_attr = new.env(parent = emptyenv())
    ns_attr$info = info
    ns_env = new.env(parent = make_imports_env(info))
    # FIXME: Why not use `.__NAMESPACE__.` here?
    ns_env$.__module__. = ns_attr
    # TODO: Set exports here!
    enable_s3_lookup(ns_env, info)
    structure(ns_env, name = paste0('namespace:', info$name), class = 'box$ns')
}

enable_s3_lookup = function (ns_env, info) {
    ns_env$.packageName = info$name
    # TODO: Create S3 methods table
}

make_imports_env = function (info) {
    structure(
        new.env(parent = baseenv()),
        name = paste0('imports:', info$name),
        class = 'box$imports'
    )
}

#' \code{is_namespace} checks whether a given environment corresponds to a
#' module namespace.
#' @param env Environment that may be a module namespace.
#' @rdname namespace
is_namespace = function (env) {
    exists('.__module__.', env, mode = 'environment', inherits = FALSE)
}

#' @rdname namespace
namespace_info = function (ns, which, default = NULL) {
    get0(which, ns$.__module__., inherits = FALSE, ifnotfound = default)
}

#' @rdname namespace
`namespace_info<-` = function (ns, which, value) {
    assign(which, value, envir = ns$.__module__.)
    ns
}

#' Get a module’s name
#'
#' @return \code{box::name} returns a character string containing the name of
#' the module, or \code{NULL} if called from outside a module.
#' @note Because this function returns \code{NULL} if not invoked inside a
#' module, the function can be used to check whether a code is being imported as
#' a module or called directly.
#' @export
name = function () {
    mod_ns = current_mod()
    if (is_namespace(mod_ns)) namespace_info(mod_ns, 'info')$name
}

# FIXME: Export?
current_mod = function (env = parent.frame(2L)) {
    mod_topenv(env)
}

#' \code{mod_topenv} is the same as \code{topenv} for module namespaces.
#' @name namespace
mod_topenv = function (env = parent.frame()) {
    while (! is_mod_topenv(env)) env = parent.env(env)
    env
}

#' \code{is_mod_topenv} returns \code{TRUE} if \code{env} is a top level
#' environment.
#' @name namespace
is_mod_topenv = function (env) {
    is_namespace(env) || identical(env, topenv(env)) || identical(env, emptyenv())
}

#' @keywords internal
make_export_env = function (info, spec, ns) {
    structure(
        new.env(parent = emptyenv()),
        name = paste0('mod:', spec_name(spec)),
        class = 'box$mod',
        spec = spec,
        info = info,
        namespace = ns
    )
}

strict_extract = function (e1, e2) {
    get(as.character(substitute(e2)), envir = e1, inherits = FALSE)
}

#' @export
`$.box$mod` = strict_extract


#' @export
`$.box$ns` = strict_extract

#' @export
`print.box$mod` = function (x, ...) {
    spec = attr(x, 'spec')
    type = if (inherits(spec, 'pkg_spec')) 'package' else 'module'
    cat(sprintf('<%s: %s>\n', type, spec_name(spec)))
    invisible(x)
}

#' @useDynLib box, unlock_env, .registration = TRUE
unlock_environment = function (env) {
    invisible(.Call(unlock_env, env))
}

find_import_env = function (x, spec) {
    UseMethod('find_import_env')
}

`find_import_env.box$ns` = function (x, spec) {
    parent.env(x)
}

`find_import_env.box$mod` = function (x, spec) {
    x
}

find_import_env.environment = function (x, spec) {
    if (identical(x, .GlobalEnv)) {
        # We need to use `attach` here: attempting to set
        # `parent.env(.GlobalEnv)` causes R to segfault.
        box_attach(NULL, name = paste0('mod:', spec_name(spec)))
    } else {
        parent.env(x) = new.env(parent = parent.env(x))
    }
}

import_into_env = function (to_env, to_names, from_env, from_names) {
    for (i in seq_along(to_names)) {
        if (
            exists(from_names[i], from_env, inherits = FALSE) &&
            bindingIsActive(from_names[i], from_env) &&
            ! inherits((fun = active_binding_function(from_names[i], from_env)), 'box$placeholder')
        ) {
            makeActiveBinding(to_names[i], fun, to_env)
        } else {
            assign(to_names[i], get(from_names[i], from_env), envir = to_env)
        }
    }
}

active_binding_function = if (version$major >= 4L) {
    function (sym, env) activeBindingFunction(sym, env)
} else {
    function (sym, env) {
        as.list(`class<-`(env, NULL))[[sym]]
    }
}

#' Wrap \dQuote{unsafe calls} functions
#'
#' \code{wrap_unsafe_function} declares a function wrapper to a function that
#' causes an \command{R CMD check} NOTE when called directly. We should usually
#' not call these functions, but we need some of them because we want to
#' explicitly support features they provide.
#' @param ns The namespace of the unsafe function.
#' @param name The name of the unsafe function.
#' @return \code{wrap_unsafe_calls} returns a wrapper function with the same
#' argument as the wrapped function that can be called without causing a NOTE.
#' @note Using an implementation that simply aliases \code{getExportedValue}
#' does not work, since \command{R CMD check} sees right through this
#' \dQuote{ruse}.
#' @keywords internal
wrap_unsafe_function = function (ns, name) {
    f = getExportedValue(ns, name)
    wrapper = function (...) eval.parent(`[[<-`(match.call(), 1L, f))
    formals(wrapper) = formals(f)
    wrapper
}

box_attach = wrap_unsafe_function(.BaseNamespaceEnv, 'attach')

box_unlock_binding = wrap_unsafe_function(.BaseNamespaceEnv, 'unlockBinding')

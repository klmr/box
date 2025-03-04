#' Module namespace handling
#'
#' \code{make_namespace} creates a new module namespace.
#' @param info the module info.
#' @return \code{make_namespace} returns the newly created module namespace for
#' the module described by \code{info}.
#' @details
#' The namespace contains a module’s content. This schema is very much like R
#' package organisation. A good resource for this is:
#' <http://obeautifulcode.com/R/How-R-Searches-And-Finds-Stuff/>
#' @note Module namespaces aren’t actual R package namespaces. This is
#' intentional, since R makes strong assumptions about package namespaces that
#' are violated here. In particular, such namespaces would have to be registered
#' in R’s internal namespace registry, and their (de)serialisation is handled by
#' R code which assumes that they belong to actual packges that can be loaded
#' via `loadNamespace`.
#' @name namespace
#' @keywords internal
make_namespace = function (info) {
    # Packages use `baseenv()` instead of `emptyenv()` for the parent
    # environment of `.__NAMESPACE__.`. I don’t know why: there should never be
    # any need for inherited name lookup. We’re only using an environment for
    # `.__module__.` to get a mutable value store.
    ns_attr = new.env(parent = emptyenv())
    ns_attr$info = info
    ns_env = new.env(parent = make_imports_env(info))
    ns_env$.__module__. = ns_attr
    # TODO: Set exports here!
    enable_s3_lookup(ns_env, info)
    structure(ns_env, name = paste0('namespace:', info$name), class = 'box$ns')
}

enable_s3_lookup = function (ns_env, info) {
    ns_env$.packageName = info$name
    # TODO: Create S3 methods table
}

import_decl = function (ns, spec, info) {
    structure(list(ns = ns, spec = spec, info = info), class = 'box$import_decl')
}

make_imports_env = function (info) {
    structure(
        new.env(parent = import_env_parent),
        name = paste0('imports:', info$name),
        class = 'box$imports'
    )
}

legacy_warn_msg = c(
    'Using {call;"} inside a module may cause issues; see the FAQ at ',
    '`{call("vignette", "faq", package = "box")}` for details.'
)

box_library = function (...) {
    warning(fmt(legacy_warn_msg, call = 'library'))
    eval.parent(`[[<-`(match.call(), 1L, library))
}

box_require = function (...) {
    warning(fmt(legacy_warn_msg, call = 'require'))
    eval.parent(`[[<-`(match.call(), 1L, require))
}

box_source = function (file, local = FALSE, ...) {
    if (is.logical(local) && ! local) {
        warning(fmt(legacy_warn_msg, call = 'source'))
    }
    eval.parent(`[[<-`(match.call(), 1L, source))
}

legacy_intercept_env = list2env(
    list(
        library = box_library,
        require = box_require,
        source = box_source
    ),
    parent = baseenv()
)

#' \code{is_namespace} checks whether a given environment corresponds to a
#' module namespace.
#' @param env an environment that may be a module namespace.
#' @rdname namespace
is_namespace = function (env) {
    exists('.__module__.', env, mode = 'environment', inherits = FALSE)
}

#' @param ns the module namespace environment.
#' @param which the key (as a length 1 character string) of the info to get/set.
#' @param default default value to use if the key is not set.
#' @rdname namespace
namespace_info = function (ns, which, default = NULL) {
    get0(which, ns$.__module__., inherits = FALSE, ifnotfound = default)
}

#' @param value the value to assign to the specified key.
#' @rdname namespace
`namespace_info<-` = function (ns, which, value) {
    assign(which, value, envir = ns$.__module__.)
    ns
}

#' Get a module’s name
#'
#' @usage \special{box::name()}
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

#' Get a module’s namespace environment
#'
#' Called inside a module, \code{box::topenv()} returns the module namespace
#' environment. Otherwise, it behaves similarly to \code{\link[base]{topenv}}.
#' @usage \special{box::topenv()}
#' @usage \special{box::topenv(env)}
#' @param module a module environment
#' @return \code{box::topenv()} returns the top-level module environment of the
#' module it is called from, or the nearest top-level non-module environment
#' otherwise; this is usually \code{.GlobalEnv}.
#'
#' \code{box::topenv(env)} returns the nearest top-level environment that is a
#' direct or indirect parent of \code{env}.
#' @export
topenv = function (module) {
    if (missing(module)) module = current_mod()
    if (inherits(module, 'box$mod')) attr(module, 'namespace')
    else mod_topenv(module)
}

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
    is_namespace(env) || env %==% base::topenv(env) || env %==% emptyenv()
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
    # Implemented in C since this function is called very frequently and needs
    # to be fast, and the C implementation is about 270% faster than an R
    # implementation based on `get`, and provides more readable error messages.
    # In fact, the fastest code that manages to provide a readable error message
    # that contains the actual call ("foo$bar") rather than only mentioning the
    # `get` function call, is more than 350% slower.
    .Call(c_strict_extract, e1, e2, environment())  # or .External(c_strict_extract, e1, e2, environment())
}

#' @export
`$.box$mod` = strict_extract

#' @export
`$.box$ns` = strict_extract

#' @export
`print.box$mod` = function (x, ...) {
    spec = attr(x, 'spec')
    type = if (inherits(spec, 'pkg_spec')) 'package' else 'module'
    cat(fmt('<{type}: {spec_name(spec)}>\n'))
    invisible(x)
}

unlock_environment = function (env) {
    invisible(.Call(c_unlock_env, env))
}

find_import_env = function (x, spec, info, mod_ns) {
    UseMethod('find_import_env')
}

`find_import_env.box$ns` = function (x, spec, info, mod_ns) {
    parent.env(x)
}

`find_import_env.box$mod` = function (x, spec, info, mod_ns) {
    x
}

find_import_env.environment = function (x, spec, info, mod_ns) {
    env = if (x %==% .GlobalEnv) {
        # We need to use `attach` here: attempting to set
        # `parent.env(.GlobalEnv)` causes R to segfault.
        box_attach(NULL, name = paste0('mod:', spec_name(spec)))
    } else {
        parent.env(x) = new.env(parent = parent.env(x))
    }
    structure(env, class = 'box$mod', spec = spec, info = info, namespace = mod_ns)
}

import_into_env = function (to_env, to_names, from_env, from_names) {
    for (i in seq_along(to_names)) {
        if (
            exists(from_names[i], from_env, inherits = FALSE)
            && bindingIsActive(from_names[i], from_env)
            && ! inherits((fun = activeBindingFunction(from_names[i], from_env)), 'box$placeholder')
        ) {
            makeActiveBinding(to_names[i], fun, to_env)
        } else {
            assign(to_names[i], env_get(from_env, from_names[i]), envir = to_env)
        }
    }
}

env_get = function (env, name) {
    UseMethod('env_get')
}

# Method for package namespace environments. This distinction is necessary since
# lazydata in packages can’t be loaded via `get`.
env_get.environment = function (env, name) {
    getExportedValue(env, name)
}

`env_get.box$mod` =
`env_get.box$ns` = function (env, name) {
    # Explicitly allow inherited values, which is used to support re-exporting
    # imports in modules.
    get(name, envir = env)
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

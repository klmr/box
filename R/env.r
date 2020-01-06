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
    structure(ns_env, name = paste0('namespace:', info$name), class = 'mod$ns')
}

enable_s3_lookup = function (ns_env, info) {
    ns_env$.packageName = info$name
    # TODO: Create S3 methods table
}

make_imports_env = function (info) {
    structure(
        new.env(parent = .BaseNamespaceEnv),
        name = paste0('imports:', info$name),
        class = 'mod$imports'
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
#' @return \code{mod::name} returns a character string containing the name of
#' the module, or \code{NULL} if called from outside a module.
#' @note Because this function returns \code{NULL} if not invoked inside a
#' module, the function can be used to check whether a code is being imported as
#' a module or called directly.
#' @export
name = function () {
    mod_ns = current_mod()
    if (! is_namespace(mod_ns)) return(NULL)
    namespace_info(mod_ns, 'info')$name
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

#' \code{is_topenv} returns a logical determining if \code{env} is a top level
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
        class = 'mod$mod',
        spec = spec,
        info = info,
        namespace = ns
    )
}

`$.mod$mod` = function (e1, e2) {
    get(as.character(substitute(e2)), envir = e1, inherits = FALSE)
}

`print.mod$mod` = function (x, ...) {
    spec = attr(x, 'spec')
    type = if (inherits(spec, 'pkg_spec')) 'package' else 'module'
    cat(sprintf('<%s: %s>\n', type, spec_name(spec)))
    invisible(x)
}

#' @useDynLib mod, unlock_env, .registration = TRUE
unlock_environment = function (env) {
    invisible(.Call(unlock_env, env))
}

find_import_env = function (x, spec) {
    UseMethod('find_import_env')
}

`find_import_env.mod$ns` = function (x, spec) {
    parent.env(x)
}

`find_import_env.mod$mod` = function (x, spec) {
    x
}

find_import_env.environment = function (x, spec) {
    if (identical(x, .GlobalEnv)) {
        attach(NULL, name = paste0('mod:', spec_name(spec)))
    } else {
        parent.env(x) = new.env(parent = parent.env(x))
    }
}

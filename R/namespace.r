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
    # FIXME: Set exports here!
    # FIXME: Create S3 methods table
    structure(ns_env, class = 'mod$ns')
}

make_imports_env = function (info) {
    structure(
        new.env(parent = .BaseNamespaceEnv),
        name = paste0('imports:', spec_name(info$spec)),
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

#' @export
name = function () {
    mod_ns = current_mod()
    if (! is_namespace(mod_ns)) return(NULL)
    # FIXME: Remove legacy code.
    mod_ns$.__module__.$name %||% namespace_info(mod_ns, 'info')$spec$name
}

# FIXME: Export?
current_mod = function (env = parent.frame(2L)) {
    mod_topenv(env)
}

#' \code{mod_topenv} is the same as \code{topenv} for module namespaces.
#' @name namespace
mod_topenv = function (env = parent.frame()) {
    is_topenv = function (env) {
        is_namespace(env) || isNamespace(env) || identical(env, .GlobalEnv)
    }

    while (! is_topenv(env)) env = parent.env(env)
    env
}


#' @keywords internal
make_export_env = function (info) {
    structure(
        new.env(parent = emptyenv()),
        name = paste0('mod:', spec_name(info$spec)),
        class = 'mod$mod',
        info = info
    )
}

`$.mod$mod` = function (e1, e2) {
    get(as.character(substitute(e2)), envir = e1, inherits = FALSE)
}

`print.mod$mod` = function (x, ...) {
    spec = attr(x, 'info')$spec
    type = if (inherits(spec, 'pkg_spec')) 'package' else 'module'
    cat(sprintf('<%s: %s>\n', type, spec_name(spec)))
    invisible(x)
}

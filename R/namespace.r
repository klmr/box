#' Module namespace handling
#'
#' The namespace contains a module’s content. This schema is very much like R
#' package organisation. A good resource for this is:
#' <http://obeautifulcode.com/R/How-R-Searches-And-Finds-Stuff/>
#' @name namespace
#' @keywords internal
make_namespace = function (info) {
    ns_attr = new.env(parent = baseenv())
    ns_attr$info = info
    # FIXME: Should the parent be an import environment instead, as for packages?
    ns_env = new.env(parent = .BaseNamespaceEnv)
    # FIXME: Why not use `.__NAMESPACE__.` here?
    ns_env$.__module__. = ns_attr
    # FIXME: Set exports here!
    # FIXME: Create S3 methods table
    ns_env
}

#' @rdname namespace
is_namespace = function (env) {
    # Use `get0` rather than `$` in case `env` is of type `mod$mod`.
    ! is.null(get0('.__module__.', env, inherits = FALSE))
    # inherits(get0('.__module__.', env, inherits = FALSE), 'mod_info')
}

#' @rdname namespace
get_namespace_info = function (ns, which) {
    get0(which, ns$.__module__., inherits = FALSE)
}

#' @rdname namespace
set_namespace_info = function (ns, which, value) {
    assign(which, value, envir = ns$.__module__.)
}

#' @export
name = function () {
    mod_ns = current_mod()
    if (! is_namespace(mod_ns)) return(NULL)
    # FIXME: Remove legacy code.
    mod_ns$.__module__.$name %||%
    # spec_name(get_namespace_info(mod_ns, 'info')$spec)
    get_namespace_info(mod_ns, 'info')$spec$name
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
make_mod_env = function (info, caller) {
    structure(
        new.env(parent = parent.env(caller)),
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

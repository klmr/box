#' @export
export = function (...) {
    caller =  parent.frame()
    # TODO: Should we also allow this from inside packages?
    if (! is_namespace(caller)) {
        stop('`mod::export` can only be called from directly inside a module')
    }

    # Find the environment from which the module calling `export` is imported.
    # Go up chain of function calls until the first call that is no longer in
    # the {mod} package.
    n = 2L
    pkg_ns_env = parent.env(environment())
    while (
        identical((env = mod_topenv(parent.frame(n))), pkg_ns_env) ||
        identical(env, .BaseNamespaceEnv)
    ) {
        n = n + 1L
    }
    import_into_env = parent.frame(n)

    call = match.call()
    for (i in seq_along(call)[-1L]) {
        export_one(call[[i]], import_into_env)
    }
}

export_one = function (declaration, import_into_env) {
    spec = parse_spec(declaration, NULL)
    info = rethrow_on_error(find_mod(spec), sys.call(-1L))
    mod_ns = load_mod(info)
    mod_env = export_symbols(info, mod_ns, import_into_env)
}

export_symbols = function (info, ns, import_into_env) {
    exports = get_exports(ns)
    list2env(mget(exports, ns, inherits = FALSE), envir = import_into_env)
    # TODO: Make exports list into a named list of actual symbols (FIXME: only
    # works for functions! — no, it always works: non-function objects simply
    # get copied upon exporting) and, in this function, add those from the
    # submodule to it. Does this also work for packages?
    # set_exports(caller, info, mod_ns, exports)
}

#' Import a module or package
#'
#' @usage
#' mod::use(prefix/mod, ...)
#' mod::use(pkg, ...)
#'
#' mod::use(alias = prefix/mod, ...)
#'
#' mod::use(prefix/mod[attach_list], ...)
#' @param ... one or more module import declarations, of the following form:
#' @param prefix/mod foo
#' @param pkg bar
#' @param alias baz
#' @param prefix/mod_name[attach_list] qux
#' @return \code{mod::use} is called for its side-effect.
#'
#' @details Modules and packages are loaded into a dedicated namespace
#' environment. Names from a module can be selectively attached to the current
#' scope.
#'
#' Modules are searched in the module search path \code{mod::option('path')}.
#' This is a vector of paths to consider, from the highest to the lowest
#' priority. The current directory is \emph{always} considered last. That is,
#' if a file \code{a.r} exists both in the current directory and in a module
#' search path, the local file \code{./a.r} will not be loaded, unless the
#' import is explicitly specified as \code{mod::use(./a)}.
#'
#' Module names can be fully qualified to refer to nested paths. See
#' \emph{Examples}.
#'
#' Module source code files are assumed to be encoded in UTF-8 without BOM.
#' Ensure that this is the case when using an extended character set.
#'
#' @note Unlike for \code{\link{library}}, attaching happens \emph{locally}: If
#' \code{mod::use} is executed in the global environment, the effect is the
#' same. Otherwise, the imported module is inserted as the parent of the current
#' \code{environment()}. When used (globally) \emph{inside} a module, the newly
#' imported module is only available inside the module’s scope, not outside it
#' (nor in other modules which might be loaded).
#'
#' @examples
#' \dontrun{
#' # `a.r` is a file in the local directory containing a function `f`.
#' a = mod::use(./a)
#' a$f()
#'
#' # b/c.r is a file in path `b`, containing functions `f` and `g`.
#' mod::use(b/c[f])
#' # No module name qualification necessary
#' f()
#' g() # Error: could not find function "g"
#'
#' mod::use(b/c[...])
#' f()
#' g()
#' }
#' @seealso \code{\link{unload}}
#' @seealso \code{\link{reload}}
#' @seealso \code{\link{name}}
#' @seealso \code{\link{help}}
#' @export
use = function (...) {
    caller = parent.frame()
    call = match.call()
    aliases = names(call)
    for (i in seq_along(call)[-1L]) {
        use_one(call[[i]], aliases[[i]], caller)
    }
}

use_one = function (declaration, alias, caller) {
    spec = parse_spec(declaration, alias)
    info = rethrow_on_error(find_mod(spec), sys.call(-1L))
    mod_ns = load_mod(info)

    register_as_import(info, mod_ns, declaration, caller)

    if (is_mod_still_loading(info)) {
        # Module was cached but hasn’t fully loaded yet. This happens for
        # circular imports (1. A -> 2. B -> 3. A)) in step (3). To proceed, we
        # take note of the issue and wait until we bounce back to step (1) to
        # perform deferred finalization.
        defer_import_finalization(declaration, spec, info, mod_ns, caller)
        return()
    }

    finalize_deferred(info)
    export_and_attach(declaration, spec, info, mod_ns, caller)

    # TODO: Lock environment? Lock bindings?! The latter breaks some tests.
    # lockEnvironment(mod_ns, bindings = FALSE)
}

register_as_import = function (info, mod_ns, declaration, caller) {
    if (is_namespace(caller)) {
        # Import declarations are stored in a list in the module metadata
        # dictionary. They are looked up by their `mod::use` call signature.
        import_decl = structure(mod_ns, expr = declaration, info = info)
        existing_imports = namespace_info(caller, 'imports', list())
        namespace_info(caller, 'imports') = c(existing_imports, import_decl)
    }
}

defer_import_finalization = function (declaration, spec, info, mod_ns, caller) {
    defer_args = as.list(environment())
    # Double quote “declaration” arg, since `eval`, `do.call` and equivalent R
    # functions evaluate the first level of quoted arguments:
    #   do.call(class, alist(1 + 2)) == 'numeric'
    defer_args$declaration = enquote(declaration)

    existing_deferred = attr(loaded_mods[[info$source_path]], 'deferred')
    attr(loaded_mods[[info$source_path]], 'deferred') =
        c(existing_deferred, list(defer_args))
}

finalize_deferred = function (info) {
    UseMethod('finalize_deferred')
}

finalize_deferred.mod_info = function (info) {
    deferred = attr(loaded_mods[[info$source_path]], 'deferred')
    if (is.null(deferred)) return()

    attr(loaded_mods[[info$source_path]], 'deferred') = NULL

    for (defer_args in deferred) {
        do.call(export_and_attach, defer_args)
    }
}

finalize_deferred.pkg_info = function (info) {
}

export_and_attach = function (declaration, spec, info, mod_ns, caller) {
    mod_exports = mod_exports(info, mod_ns)
    attach_to_caller(spec, mod_exports, caller)
    assign_alias(spec, mod_exports, caller)
}

load_mod = function (info) {
    UseMethod('load_mod')
}

load_from_source = function (info, mod_ns) {
    # R, Windows and Unicode don’t play together. `source` does not work here.
    # See http://developer.r-project.org/Encodings_and_R.html and
    # http://stackoverflow.com/q/5031630/1968 for a discussion of this.
    exprs = parse(info$source_path, encoding = 'UTF-8')
    eval(exprs, mod_ns)
    namespace_info(mod_ns, 'exports') = parse_export_specs(info, mod_ns)
    # TODO: When do we load the documentation?
    # namespace_info(mod_ns, 'doc') = parse_documentation(info, mod_ns)
    make_S3_methods_known(mod_ns)
}

load_mod.mod_info = function (info) {
    message(glue::glue('load_module({info})\n'))

    if (is_mod_loaded(info)) return(loaded_mod(info))

    # Load module/package and dependencies; register the module now, to allow
    # cyclic imports without recursing indefinitely — but deregister upon
    # failure to load.
    on.exit(deregister_mod(info))

    mod_ns = make_namespace(info)
    register_mod(info, mod_ns)
    load_from_source(info, mod_ns)
    mod_loading_finished(info, mod_ns)

    on.exit()
    mod_ns
}

load_mod.pkg_info = function (info) {
    pkg = info$spec$name
    base::.getNamespace(pkg) %||% loadNamespace(pkg)
}

mod_exports = function (info, ns) {
    UseMethod('mod_exports')
}

mod_exports.mod_info = function (info, ns) {
    # TODO: Create copy instead of reusing the identical mod export environment?
    if (! is.null((mod = namespace_info(ns, 'mod')))) return(mod)

    env = make_export_env(info)
    namespace_info(ns, 'mod') = env
    exports = namespace_info(ns, 'exports')

    export_names_into(exports, ns, env)
    reexport_names_into(exports, ns, env)

    # FIXME: Lock namespace and/or ~-bindings?
    # lockEnvironment(env, bindings = TRUE)
    env
}

mod_exports.pkg_info = function (info, ns) {
    env = make_export_env(info)
    exports = getNamespaceExports(ns)
    list2env(mget(exports, ns, inherits = TRUE), envir = env)
    # FIXME: Handle lazydata & depends
    lockEnvironment(env, bindings = TRUE)
    env
}

export_names_into = function (exports, ns, env) {
    direct_exports = exports[attr(exports, 'assignments')]
    list2env(mget(names(direct_exports), ns, inherits = FALSE), envir = env)
}

find_matching_import = function (imports, reexport) {
    reexport_expr = attr(reexport, 'call')[[-1L]]
    for (import in imports) {
        if (identical(attr(import, 'expr'), reexport_expr)) return(import)
    }
}

reexport_names_into = function (exports, ns, env) {
    reexports = exports[attr(exports, 'imports')]
    imports = namespace_info(ns, 'imports')

    for (reexport in reexports) {
        import_ns = find_matching_import(imports, reexport)
        import_info = attr(import_ns, 'info')
        import_spec = import_info$spec

        if (is_mod_still_loading(import_info)) {
            declaration = attr(reexport, 'call')[[-1L]]
            defer_import_finalization(declaration, import_spec, import_info, import_ns, env)
            next
        }

        import_exports = mod_exports(import_info, import_ns)
        attach_to_caller(import_spec, import_exports, env)
        assign_alias(import_spec, import_exports, env)
    }
}

attach_to_caller = function (spec, mod_exports, caller) {
    if (is.null(spec$attach)) return()
    is_wildcard = is.na(spec$attach)
    name_spec = spec$attach[! is_wildcard]
    import_env = find_import_env(caller, spec)

    if (! all(is_wildcard) && any((missing = ! name_spec %in% ls(mod_exports)))) {
        stop(sprintf(
            'Name%s %s not exported by %s',
            if (length(name_spec[missing]) > 1L) 's' else '',
            paste(sQuote(name_spec[missing]), collapse = ', '),
            spec_name(spec)
        ))
    }

    if (any(is_wildcard)) {
        attach_list = ls(mod_exports)
        if (length(attach_list) == 0L) return()

        aliases = attach_list
        if (length(spec$attach) > 1L) {
            # Substitute aliased names in export list
            to_replace = match(name_spec, attach_list)
            aliases[to_replace] = names(name_spec)
        }
    } else {
        attach_list = spec$attach
        aliases = names(attach_list)
    }

    attr(mod_exports, 'attached') = environmentName(import_env)
    list2env(setNames(mget(attach_list, mod_exports), aliases), envir = import_env)
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
        parent.env(x) = structure(new.env(parent = parent.env(x)))
    }
}

#' Assign module/package object in calling environment, unless attached, and
#' no explicit alias given.
#' @keywords internal
assign_alias = function (spec, mod_exports, caller) {
    create_mod_alias = is.null(spec$attach) || spec$explicit
    if (! create_mod_alias) return()

    assign(spec$alias, mod_exports, caller)
}

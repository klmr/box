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
#' @seealso \code{\link{path}}
#' @seealso \code{\link{file}}
#' @seealso \code{\link{help}}
#' @export
use = function (...) {
    caller = parent.frame()
    call = match.call()
    imports = call[-1L]
    aliases = names(imports) %||% rep(list(NULL), length(imports))
    invisible(Map(use_one, imports, aliases, list(caller)))
}

use_one = function (declaration, alias, caller) {
    spec = parse_spec(declaration, alias)
    info = rethrow_on_error(find_mod(spec), sys.call(-1L))
    load_and_register(spec, info, caller)
}

load_and_register = function (spec, info, caller) {
    mod_ns = load_mod(info)
    register_as_import(spec, info, mod_ns, caller)

    if (is_mod_still_loading(info)) {
        # Module was cached but hasn’t fully loaded yet. This happens for
        # circular imports (1. A -> 2. B -> 3. A)) in step (3). To proceed, we
        # take note of the issue and wait until we bounce back to step (1) to
        # perform deferred finalization.

        assign_temp_alias(spec, caller)
        defer_import_finalization(spec, info, mod_ns, caller)
        return()
    }

    export_and_attach(spec, info, mod_ns, caller)

    # TODO: Lock bindings?! This breaks some tests.
    lockEnvironment(mod_ns, bindings = FALSE)
}

register_as_import = function (spec, info, mod_ns, caller) {
    if (is_namespace(caller)) {
        # Import declarations are stored in a list in the module metadata
        # dictionary. They are looked up by their spec.
        import_decl = structure(mod_ns, spec = spec, info = info)
        existing_imports = namespace_info(caller, 'imports', list())
        namespace_info(caller, 'imports') = c(existing_imports, import_decl)
    }
}

defer_import_finalization = function (spec, info, mod_ns, caller) {
    defer_args = as.list(environment())
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

finalize_deferred.pkg_info = function (info) {}

export_and_attach = function (spec, info, mod_ns, caller) {
    finalize_deferred(info)
    mod_exports = mod_exports(info, spec, mod_ns)
    if (is.null(mod_exports)) return()
    assign_alias(spec, mod_exports, caller)
    attach_to_caller(spec, mod_exports, caller)
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

load_mod = function (info) {
    UseMethod('load_mod')
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
    pkg = info$name
    base::.getNamespace(pkg) %||% loadNamespace(pkg)
}

#' Exported module objects
#'
#' \code{mod_exports} returns an export environment containing a copy of the
#' module’s exported objects.
mod_exports = function (info, spec, ns) {
    exports = mod_export_names(info, ns)
    if (is.null(exports)) return()

    env = make_export_env(info, spec, ns)
    list2env(mget(exports, ns, inherits = TRUE), envir = env)

    lockEnvironment(env, bindings = TRUE)
    env
}

#' @return \code{mode_export_names} returns the same as
#' \code{names(mod_exports(info, spec, ns))} and does not create an export environment.
#' @name mod_exports
#' @keywords internal
mod_export_names = function (info, ns) {
    UseMethod('mod_export_names')
}

mod_export_names.mod_info = function (info, ns) {
    namespace_info(ns, 'exports')
}

mod_export_names.pkg_info = function (info, ns) {
    getNamespaceExports(ns)
}

attach_to_caller = function (spec, mod_exports, caller) {
    attach_list = attach_list(spec, mod_exports)
    if (is.null(attach_list)) return()

    import_env = find_import_env(caller, spec)
    attr(mod_exports, 'attached') = environmentName(import_env)
    imports = setNames(mget(attach_list, mod_exports), names(attach_list))
    list2env(imports, envir = import_env)
}

attach_list = function (spec, exports) {
    if (is.null(spec$attach)) return()
    is_wildcard = is.na(spec$attach)
    name_spec = spec$attach[! is_wildcard]

    if (! all(is_wildcard) && any((missing = ! name_spec %in% ls(exports)))) {
        stop(sprintf(
            'Name%s %s not exported by %s',
            if (length(name_spec[missing]) > 1L) 's' else '',
            paste(sQuote(name_spec[missing]), collapse = ', '),
            spec_name(spec)
        ))
    }

    if (any(is_wildcard)) {
        attach_list = ls(exports)
        if (length(attach_list) == 0L) return()

        aliases = attach_list
        if (length(spec$attach) > 1L) {
            # Substitute aliased names in export list
            to_replace = match(name_spec, attach_list)
            aliases[to_replace] = names(name_spec)
        }

        setNames(attach_list, aliases)
    } else {
        name_spec
    }
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

#' Assign module/package object in calling environment, unless attached, and
#' no explicit alias given.
#' @keywords internal
assign_alias = function (spec, mod_exports, caller) {
    create_mod_alias = is.null(spec$attach) || spec$explicit
    if (! create_mod_alias) return()

    assign(spec$alias, mod_exports, caller)
}

assign_temp_alias = function (spec, caller) {
    create_mod_alias = is.null(spec$attach) || spec$explicit
    if (! create_mod_alias) return()

    callers = list()

    binding = function (mod_exports) {
        if (missing(mod_exports)) {
            # Find from where I’m called, and infer the target of the export.
            mod_exports_frame_index = tail(which(vapply(
                sys.calls(),
                function (call) identical(call[[1L]], quote(mod_exports)),
                logical(1L)
            )), 1L)
            frame = sys.frame(mod_exports_frame_index)
            env = frame$env
            assign('callers', append(callers, env), envir = parent.env(environment()))

            # FIXME: Do we need to create transitive placeholder active bindings?
            structure(list(), class = 'placeholder')
        } else {
            # Resolve assignments
            for (env in callers) {
                assign(spec$alias, mod_exports, envir = env)
            }
            # Replace myself
            rm(list = spec$alias, envir = caller)
            assign(spec$alias, mod_exports, envir = caller)
        }
    }

    makeActiveBinding(spec$alias, binding, caller)
}

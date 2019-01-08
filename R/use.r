#' Import a module or package
#'
#' @param ... one or more module import declarations
#' @usage
#' mod::use(prefix/mod_name, ...)
#' mod::use(pkg_name, ...)
#'
#' mod::use(mod_alias = prefix/mod_name, ...)
#'
#' mod::use(prefix/mod_name[attach_list], ...)
#' @param prefix/mod_name foo
#' @param pkg_name bar
#' @param mod_alias baz
#' @param prefix/mod_name[attach_list] qux
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
    if (is_namespace(caller)) {
        # Import declarations are stored in a list in the module metadata
        # dictionary. They are looked up by their `mod::use` call signature.
        import_decl = structure(mod_ns, expr = declaration, info = info)
        existing_imports = get_namespace_info(caller, 'imports', list())
        set_namespace_info(caller, 'imports', c(existing_imports, import_decl))
    }
    mod_exports = get_mod_exports(info, mod_ns, caller)
    attach_to_caller(spec, mod_exports, caller)
    assign_alias(spec, mod_exports, caller)
}

load_mod = function (info) {
    UseMethod('load_mod')
}

########### FIXME: Move this block into its own file.

loaded_mods = new.env(parent = emptyenv())

is_mod_loaded = function (info) {
    # TODO: Use
    #   exists(info$source_path, envir = loaded_mods, inherits = FALSE)
    # instead?
    info$source_path %in% names(loaded_mods)
}

loaded_mod = function (info) {
    loaded_mods[[info$source_path]]
}

register_mod = function (info, mod_ns) {
    # TODO: use
    #   assign(info$source_path, mod_ns, envir = loaded_mods)
    # instead?
    loaded_mods[[info$source_path]] = mod_ns
}

deregister_mod = function (info, mod_ns) {
    rm(list = info$source_path, envir = loaded_mods)
}

###########

load_from_source = function (info, mod_ns) {
    exprs = parse(info$source_path, encoding = 'UTF-8')
    eval(exprs, mod_ns)
    set_namespace_info(mod_ns, 'exports', parse_export_specs(info, mod_ns))
    # TODO: When do we load the documentation?
    # set_namespace_info(mod_ns, 'doc', parse_documentation(info, mod_ns))
    make_S3_methods_known(mod_ns)
    # TODO: Lock environment? Lock bindings?! The latter breaks some tests.
    lockEnvironment(mod_ns, bindings = FALSE)
}

load_mod.mod_info = function (info) {
    message(glue::glue('load_module({info})\n'))

    if (is_mod_loaded(info)) return(loaded_mod(info))

    # Load module/package and dependencies; register — but deregister upon
    # failure to load.
    on.exit(deregister_mod(info))

    mod_ns = make_namespace(info)
    register_mod(info, mod_ns)
    load_from_source(info, mod_ns)

    on.exit()
    mod_ns
}

load_mod.pkg_info = function (info) {
    loadNamespace(info$spec$name)
}

get_mod_exports = function (info, ns, caller) {
    UseMethod('get_mod_exports')
}

get_mod_exports.mod_info = function (info, ns, caller) {
    env = make_export_env(info)
    exports = get_namespace_info(ns, 'exports')
    direct_exports = exports[attr(exports, 'assignments')]
    list2env(mget(names(direct_exports), ns, inherits = FALSE), envir = env)

    reexports = exports[attr(exports, 'imports')]
    imports = get_namespace_info(ns, 'imports')

    find_matching_import = function (imports, reexport) {
        reexport_expr = attr(reexport, 'call')[[-1L]]
        for (import in imports) {
            if (identical(attr(import, 'expr'), reexport_expr)) return(import)
        }
    }

    for (reexport in reexports) {
        import_ns = find_matching_import(imports, reexport)
        import_info = attr(import_ns, 'info')
        import_spec = import_info$spec
        import_exports = get_mod_exports(import_info, import_ns, env)
        attach_to_caller(import_spec, import_exports, env)
        assign_alias(import_spec, import_exports, env)
    }

    # TODO: Lock namespace and/or ~-bindings?
    lockEnvironment(env, bindings = TRUE)
    env
}

get_mod_exports.pkg_info = function (info, ns, caller) {
    env = make_export_env(info)
    exports = getNamespaceExports(ns)
    list2env(mget(exports, ns, inherits = FALSE), envir = env)
    # FIXME: Handle lazydata & depends
    lockEnvironment(env, bindings = TRUE)
    env
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

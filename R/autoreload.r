#' Auto-reloading of modules on change
#'
#' @usage \special{box::enable_autoreload(..., include, exclude, on_access = FALSE)}
#' @param ... ignored; present to force naming arguments
#' @param include vector of unevaluated, qualified module names to auto-reload
#'  (optional)
#' @param exclude vector of unevaluates, qualified module names to auto-reload
#'  (optional)
#' @param on_access logical value specifying whether to reload modules every
#'  time they are used, or only when they are being loaded via \code{box::use}.
#' @return \code{enable_autoreload} is called for its side effect and does not
#'  return a value.
#' @details
#' \code{include} and \code{exclude}, when given, are either single,
#' unevaluated, qualified module names (e.g. \code{./a}; \code{my/mod}) or
#' vectors of such module names (e.g. \code{c(./a, my/mod)}).
#' @name auto-reload
#' @export
enable_autoreload = function (..., include, exclude, on_access = FALSE) {
    autoreload$init(on_access)
    includes = spec_list(substitute(include))
    excludes = spec_list(substitute(exclude))
    caller = parent.frame()
    map(autoreload$add_include, includes, list(caller))
    map(autoreload$add_exclude, excludes, list(caller))
    invisible()
}

#' @rdname auto-reload
#' @export
disable_autoreload = function () {
    autoreload$reset()
    invisible()
}

#' @rdname auto-reload
#' @export
autoreload_include = function (...) {
    caller = parent.frame()
    includes = match.call(expand.dots = FALSE)$...
    map(autoreload$add_include, includes, list(caller))
    invisible()
}

#' @rdname auto-reload
#' @export
autoreload_exclude = function (...) {
    caller = parent.frame()
    excludes = match.call(expand.dots = FALSE)$...
    map(autoreload$add_exclude, excludes, list(caller))
    invisible()
}

spec_list = function (specs) {
    if (identical(specs, quote(expr =))) {
        list()
    } else if (is.call(specs) && identical(specs[[1L]], quote(c))) {
        specs[-1L]
    } else {
        list(specs)
    }
}

autoreload = local({
    self = environment()
    top = topenv()

    init = function (on_access) {
        reset()
        if (on_access) {
            self$export_env_class = export_env_class_reload
            self$import_into_env = import_into_env_reload
        }
        self$is_mod_loaded = is_mod_loaded_reload
    }

    reset = function () {
        self$includes = character()
        self$excludes = character()
        self$is_mod_loaded = is_mod_loaded_basic
        self$export_env_class = export_env_class_basic
        self$import_into_env = import_into_env_basic
    }

    add_include = function (spec, caller) {
        spec = parse_spec(spec, '')
        info = find_mod(spec, caller)

        if (length(self$includes) > 0L) {
            self$includes = c(self$includes, info$source_path)
        } else if (length(self$excludes) > 0L) {
            self$excludes = setdiff(self$excludes, info$source_path)
        } else {
            self$includes = info$source_path
        }
    }

    add_exclude = function (spec, caller) {
        spec = parse_spec(spec, '')
        info = find_mod(spec, caller)

        if (length(self$includes) > 0L) {
            self$includes = setdiff(self$includes, info$source_path)
        } else {
            self$excludes = c(self$excludes, info$source_path)
        }
    }

    included = function (info) {
        path = info$source_path

        if (length(includes) == 0L) {
            ! path %in% excludes
        } else {
            path %in% includes
        }
    }

    extract = function (e1, e2) {
        ns = attr(e1, 'namespace')
        info = namespace_info(ns, 'info')
        new_mod = if (needs_reloading(info, ns)) {
            spec = attr(e1, 'spec')
            parent = attr(e1, 'parent')
            load_and_register(spec, info, parent)
            get(spec$alias, envir = parent, inherits = FALSE)
        } else {
            e1
        }

        strict_extract(new_mod, e2)
    }

    export_env_class_basic = function (info, ns) {
        'box$mod'
    }

    export_env_class_reload = function (info) {
        c(if (included(info)) 'box$autoreload', 'box$mod')
    }

    is_mod_loaded_basic = function (info) {
        info$source_path %in% names(loaded_mods)
    }

    is_mod_loaded_reload = function (info) {
        is_mod_loaded_basic(info) && ! needs_reloading(info, loaded_mod(info))
    }

    import_into_env_basic = function (spec, info, to_env, to_names, from_env, from_names) {
        top$import_into_env(to_env, to_names, from_env, from_names)
    }

    import_into_env_reload = function (spec, info, to_env, to_names, from_env, from_names) {
        foreach(function (from, to) {
            fun = if (
                exists(from, from_env, inherits = FALSE) &&
                bindingIsActive(from, from_env) &&
                ! inherits(active_binding_function(from, from_env), 'box$placeholder')
            ) {
                function (value) {
                    new_env = if (needs_reloading(info, from_env)) {
                        load_and_register(spec, info, to_env)
                        loaded_mod(info)
                    } else {
                        from_env
                    }

                    fun = active_binding_function(from, new_env)
                    fun(value)
                }
            } else {
                function () {
                    new_env = if (needs_reloading(info, from_env)) {
                        load_and_register(spec, info, to_env)
                        loaded_mod(info)
                    } else {
                        from_env
                    }
                    get(from, envir = new_env)
                }
            }
            makeActiveBinding(to, fun, to_env)
        }, from_names, to_names)
    }

    needs_reloading = function (info, ns) {
        included(info) && (
            is_file_modified(info, ns) || {
                imports = namespace_info(ns, 'imports')
                any(map_lgl(function (x) needs_reloading(x$info, x$ns), imports))
            }
        )
    }

    reset()

    self
})

add_timestamp = function (info, ns) {
    timestamp = file.mtime(info$source_path)
    namespace_info(ns, 'timestamp') = timestamp
}

is_file_modified = function (info, ns) {
    timestamp = namespace_info(ns, 'timestamp')
    file.mtime(info$source_path) > timestamp
}

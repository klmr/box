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

    init = function (on_access) {
        reset()
        if (on_access) {
            throw('Not yet implemented')
        } else {
            self$is_mod_loaded = is_mod_loaded_reload
        }
    }

    reset = function () {
        self$includes = character()
        self$excludes = character()
        self$is_mod_loaded = is_mod_loaded_basic
    }

    add_include = function (spec, caller) {
        spec = parse_spec(spec, '')
        info = find_mod(spec, caller)
        self$excludes = setdiff(self$excludes, info$source_path)
        self$includes = c(self$includes, info$source_path)
    }

    add_exclude = function (spec, caller) {
        spec = parse_spec(spec, '')
        info = find_mod(spec, caller)
        self$includes = setdiff(self$includes, info$source_path)
        self$excludes = c(self$excludes, info$source_path)
    }

    included = function (info) {
        path = info$source_path

        if (length(includes) == 0L) {
            ! path %in% excludes
        } else {
            path %in% includes
        }
    }

    is_mod_loaded_basic = function (info) {
        info$source_path %in% names(loaded_mods)
    }

    is_mod_loaded_reload = function (info) {
        is_mod_loaded_basic(info) && ! needs_reloading(info)
    }

    needs_reloading = function (info) {
        included(info) && is_file_modified(info)
    }

    reset()

    self
})

add_timestamp = function (info) {
    timestamp = file.mtime(info$source_path)
    mod_timestamps[[info$source_path]] = timestamp
}

remove_timestamp = function (info) {
    rm(list = info$source_path, envir = mod_timestamps)
}

is_file_modified = function (info) {
    prev = mod_timestamps[[info$source_path]]
    is.null(prev) || file.mtime(info$source_path) > prev
}

mod_timestamps = new.env(parent = emptyenv())

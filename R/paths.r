#' Return the import module search path
#'
#' @note The search paths are ordered from highest to lowest priority.
#' The current module’s path always has the lowest priority.
#'
#' There are two ways of modifying the module search path: by default,
#' \code{options('mod')$path} specifies the search path as a character vector.
#' Users can override its value by separately setting the environment variable
#' \code{R_MOD_PATH} to one or more paths, separated by the platform’s path
#' separator.
#' @keywords internal
mod_search_path = function () {
    option_value = get_option('path')
    env_value = strsplit(Sys.getenv('R_MOD_PATH'), .Platform$path.sep)[[1L]]
    c(option_value, env_value, module_base_path(parent.frame()))
}

calling_mod_path = function () {
    # Go up chain of function calls until the first call that is no longer in
    # the {mod} package.
    n = 1L
    pkg_ns_env = parent.env(environment())
    while (identical((env = mod_topenv(parent.frame(n))), pkg_ns_env)) n = n + 1L

    # FIXME: Make work for modules imported inside package, if necessary.
    if (is_namespace(env)) {
        dirname(get_namespace_info(env, 'info')$source_path)
    } else {
        script_path()
    }
}

#' Split a path into its components and merge them back together
#'
#' \code{split_path(path)} is a platform independent and file system logic
#' aware alternative to \code{strsplit(path, '/')[[1L]]}.
#' @param path the path to split
#' @return \code{split_path} returns a character vector of path components that
#' logically represent \code{path}.
#' @keywords internal
split_path = function (path) {
    if (identical(path, dirname(path))) {
        path
    } else {
        c(Recall(dirname(path)), basename(path))
    }
}

#' \code{merge_path(split_path(path))} is equivalent to \code{path}.
#' @param components character string vector of path components to merge
#' @return \code{merge_path} returns a single character string that is
#' logically equivalent to the \code{path} passed to \code{split_path}.
#' logically represent \code{path}.
#' @note \code{merge_path} is the inverse function to \code{split_path}.
#' However, this does not mean that its result will be identical to the
#' original path. Instead, it is only guaranteed that it will refer to the same
#' logical path given the same working directory.
#' @rdname split_path
#' @keywords internal
merge_path = function (components) {
    do.call(file.path, as.list(components))
}

#' Path related functions
#'
#' \code{mod_search_path} returns the character vector of paths where module
#' code can be located and will be found by \pkg{box}.
#'
#' @note The search paths are ordered from highest to lowest priority.
#' The current module’s path always has the lowest priority.
#'
#' There are two ways of modifying the module search path: by default,
#' \code{getOption('box.path')} specifies the search path as a character vector.
#' Users can override its value by separately setting the environment variable
#' \env{R_BOX_PATH} to one or more paths, separated by the platform’s path
#' separator (\dQuote{:} on UNIX-like systems, \dQuote{;} on Windows).
#' @keywords internal
#' @name paths
mod_search_path = function (caller) {
    env_value = strsplit(Sys.getenv('R_BOX_PATH'), .Platform$path.sep)[[1L]]
    c(
        env_value %||% getOption('box.path'),
        system_mod_path,
        calling_mod_path(caller)
    )
}

#' \code{calling_mod_path} determines the path of the module code that is
#' currently calling into the \pkg{box} package.
#'
#' @param caller the environment from which \code{box::use} was invoked.
#' @return \code{calling_mod_path} the path of the source module that is calling
#' \code{box::use}, or the script’s path if the calling code is not a module.
#' @rdname paths
calling_mod_path = function (caller) {
    calling_ns = mod_topenv(caller)

    # FIXME: Make work for modules imported inside package, if necessary.
    if (is_namespace(calling_ns)) {
        dirname(namespace_info(calling_ns, 'info')$source_path)
    } else {
        script_path()
    }
}

#' \code{split_path(path)} is a platform independent and filesystem logic
#' aware alternative to \code{strsplit(path, '/')[[1L]]}.
#' @param path the path to split
#' @return \code{split_path} returns a character vector of path components that
#' logically represent \code{path}.
#' @rdname paths
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
#' @rdname paths
merge_path = function (components) {
    do.call('file.path', as.list(components))
}

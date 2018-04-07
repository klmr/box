#' Return the import module search path
#'
#' @note The search paths are ordered from highest to lowest priority.
#' The current module’s path always has the lowest priority.
#'
#' There are two ways of modifying the module search path: by default,
#' \code{options('import.path')} specifies the search path. If and only if that
#' is unset, R also considers the environment variable \code{R_IMPORT_PATH}.
#' @keywords internal
mod_search_path = function () {
    path_env = strsplit(Sys.getenv('R_IMPORT_PATH'), ':')[[1]] %||% NULL
    c(getOption('import.path', path_env), module_base_path(parent.frame()))
}

#' Split a path into its components and merge them back together
#'
#' \code{split_path(path)} is a platform independent and file system logic
#' aware alternative to \code{strsplit(path, '/')[[1]]}.
#' @param path the path to split
#' @return \code{split_path} returns a character vector of path components that
#' logically represent \code{path}.
#' @keywords internal
split_path = function (path) {
    if (identical(path, dirname(path)))
        path
    else
        c(Recall(dirname(path)), basename(path))
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

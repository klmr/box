#' Find the full file names of files in modules
#'
#' @param ... character vectors of files or subdirectories inside a module; if
#'  none is given, return the root directory of the module
#' @param module a module environment (default: current module)
#' @param mustWork logical; if \code{TRUE}, an error is raised if the given
#'  files do not match existing files.
#' @return A character vector containing the absolute paths to the files
#'  specified in \code{...}, or an empty string, \code{''}, if no file was
#'  found (unless \code{mustWork = TRUE} was specified).
#' @note If called from outside a module, the current working directory is used.
#'
#' This function is similar to \code{system.file} for packages. It is provided
#' as a separate function rather than overriding \code{system.file} because that
#' would cause ambiguity when a module and a package share the same name.
#' @seealso \code{\link[base]{system.file}}
#' @export
file = function (..., module = current_mod(), must_work = FALSE) {
    path = base_path(module)

    if (length(list(...)) == 0L) return(path)

    paths = file.path(path, ...)
    existing = paths[file.exists(paths)]

    existing %||% if (must_work) stop('File not found: ', sQuote(paths)) else ''
}

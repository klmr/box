#' Find the full file names of files in modules
#'
#' @param ... character vectors of files or subdirectories inside a module; if
#'  none is given, returns the root directory of the module
#' @param module a module environment (default: current module)
#' @param mustWork logical; if \code{TRUE}, an error is raised if the given
#'  files do not match existing files.
#' @return A character vector containing the absolute paths to the files
#'  specified in \code{...}, or an empty string, \code{''}, if no file was
#'  found (unless \code{mustWork = TRUE} was specified).
#' @note If called from outside a module, the current working directory is used.
#' @seealso \code{base::system.file}
#' @export
module_file = function (..., module = parent.frame(), mustWork = FALSE) {
    module_path = module_base_path(module)

    if (nargs() == 0)
        return(module_path)

    paths = file.path(module_path, ...)
    existing = paths[file.exists(paths)]

    if (length(existing) != 0)
        existing
    else
        if (mustWork)
            stop('no file found')
        else
            ''
}

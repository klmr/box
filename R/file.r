#' Find the full file names of files in modules
#'
#' @usage \special{box::file(\dots, module = current_module())}
#' @param \dots character vectors of files or subdirectories inside a module; if
#'  none is given, return the root directory of the module
#' @param module a module environment (default: current module)
#' @return A character vector containing the absolute paths to the files
#'  specified in \code{\dots}.
#'
#' @note If called from outside a module, the current working directory is used.
#'
#' This function is similar to \code{system.file} for packages. Its semantics
#' differ in the presence of non-existent files: \code{box::file} always returns
#' the requested paths, even for non-existent files; whereas \code{system.file}
#' returns empty strings for non-existent files, or fails (if requested via the
#' argument \code{mustWork = TRUE}).
#' @seealso \code{\link[base]{system.file}}
#' @export
file = function (..., module = current_mod()) {
    file.path(base_path(module), ...)
}

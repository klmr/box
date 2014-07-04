#' An alternative module system for R
#'
#' Use \code{module = import('module')} to import a module for usage.
#' Fully qualified names are supported for nested modules, reminiscent of
#' Python’s module mechanism.
#' @section Package options:
#'
#' \itemize{
#'   \item \code{import.path}:
#'     A vector of paths which are searched for modules. The paths are ordered
#'     from highest to lowest precedence – if a module of the same name exists
#'     in two paths, the first hit is accepted.
#'     The current directory is always prepended to the search paths.
#'   \item \code{import.attach}:
#'     A boolean specifying whether operators from a module should be attached
#'     by default when using \code{import}, even if \code{attach=FALSE} is
#'     specified. This option is only considered while running in interactive
#'     mode, and not inside a module. The option is furthermore overridden by
#'     explicitly passing a value to the \code{attach_operators} argument.
#' }
#'
#' @name modules
#' @docType package
#' @seealso \code{import}
#' @seealso \code{module_name}
#' @seealso \code{module_file}
#' @seealso \code{unload}, \code{reload}
#' @seealso \code{export_submodule}
NULL

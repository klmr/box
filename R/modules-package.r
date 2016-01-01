#' An alternative module system for R
#'
#' Use \code{module = import('module')} to import a module for usage, or
#' \code{module = import_package('package')} to import a package. Fully
#' qualified names are supported for nested modules, reminiscent of Python’s
#' module mechanism.
#'
#' @section S3 class support:
#'
#' Modules can contain S3 generics and methods. To override known generics
#' (defined outside modules), methods inside a module need to be registered
#' using \code{\link{register_S3_method}}. See the documentation on that
#' function for details.
#'
#' @section Package options:
#'
#' \itemize{
#'   \item \code{import.path}:
#'     A vector of paths which are searched for modules. The paths are ordered
#'     from highest to lowest precedence – if a module of the same name exists
#'     in two paths, the first hit is accepted.
#'     The current directory is always appended to the search paths.
#'   \item \code{import.attach}:
#'     A logical specifying whether functions from a module should be attached
#'     by default when using \code{import}, even if \code{attach=FALSE} is
#'     specified. This option is only considered while running in interactive
#'     mode, and not inside a module. The option is furthermore overridden by
#'     explicitly passing a value to the \code{attach_operators} argument.
#'   \item \code{import.warn_conflicts}:
#'     A logical specifying whether \code{import} and \code{import_package}
#'     should issue a warning about masked objects when attaching a module to
#'     the global object search path. This warning is only issued while running
#'     in interactive mode. The option defaults to \code{TRUE}.
#' }
#'
#' @name modules
#' @docType package
#' @seealso \code{import}
#' @seealso \code{import_package}
#' @seealso \code{module_name}
#' @seealso \code{module_file}
#' @seealso \code{unload}, \code{reload}
#' @seealso \code{export_submodule}
#' @seealso \code{register_S3_method}
NULL

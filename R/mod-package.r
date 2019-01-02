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
#' @name mod
#' @docType package
#' @seealso \code{\link{import}}
#' @seealso \code{\link{import_package}}
#' @seealso \code{\link{module_name}}
#' @seealso \code{\link{module_file}}
#' @seealso \code{\link{unload}}, \code{\link{reload}}
#' @seealso \code{\link{export_submodule}}
#' @seealso \code{\link{register_S3_method}}
#' @importFrom stats setNames
#' @importFrom utils lsf.str
NULL

#' Return mod option settings
#'
#' \code{get_option(which)} returns a {mod} related R option given by
#' \code{which}.
#' @param which name of the option to return
#' @param default value to return if option is not set (default: \code{NULL})
#' @export
get_option = function (which, default = NULL) {
    opts = getOption('mod', list())
    opts[[which]] %||% default
}

#' \code{set_option(which, value)} sets a {mod} related R option.
#' @param value new value to set the option to.
#' @rdname get_option
#' @export
set_options = function (...) {
    opts = getOption('mod', list())
    args = list(...)
    opts[names(args)] = args
    options(mod = opts)
}

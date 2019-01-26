#' An alternative module system for R
#'
#' Use \code{mod::use(prefix/mod)} to import a module, or \code{mod::use(pkg)}
#' to import a package. Fully qualified names are supported for nested modules,
#' reminiscent of module systems in many other modern languages.
#'
#' @section S3 class support:
#'
#' Modules can contain S3 generics and methods. To override known generics
#' (defined outside modules), methods inside a module need to be registered
#' using \code{\link{register_S3_method}}. See the documentation on that
#' function for details.
#'
#' @section Package options:
#' Package options should be set via \code{mod::set_options(name = value, ...)}.
#' Individual options can be queried at runtime using \code{mod::option(name)}.
#'
#' \itemize{
#'   \item \code{path}:
#'     A vector of paths which are searched for modules. The paths are ordered
#'     from highest to lowest precedence – if a module of the same name exists
#'     in two paths, the first hit is accepted.
#'     The current directory is always appended to the search paths.
#'   \item \code{warn_conflicts}:
#'     A logical specifying whether \code{mod::use} should issue a warning about
#'     masked objects when attaching a module to the global object search path.
#'     This warning is only issued while running in interactive mode. The option
#'     defaults to \code{TRUE}.
#' }
#'
#' @name mod
#' @docType package
#' @seealso \code{\link{use}}
#' @seealso \code{\link{name}}
#' @seealso \code{\link{file}}
#' @seealso \code{\link{unload}}, \code{\link{reload}}
#' @seealso \code{\link{register_S3_method}}
#' @importFrom stats setNames
#' @importFrom utils lsf.str
NULL

#' Return mod option settings
#'
#' \code{option(which)} returns a {mod} related R option given by \code{which}.
#' @param which name of the option to return
#' @param default value to return if option is not set (default: \code{NULL})
#' @export
option = function (which, default = NULL) {
    opts = getOption('mod', list())
    opts[[which]] %||% default
}

#' \code{set_options(which = value, ...)} sets one or more {mod} related R
#' options.
#' @param ... one or more key-value pairs in the form \code{key = value}.
#' @rdname option
#' @export
set_options = function (...) {
    opts = getOption('mod', list())
    args = list(...)
    opts[names(args)] = args
    options(mod = opts)
}

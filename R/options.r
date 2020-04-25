#' Set or return mod option settings
#'
#' \code{option(which)} returns a {mod} related R option given by \code{which}.
#' @param which name of the option to return
#' @param default value to return if option is not set (default: \code{NULL})
#' @name options
#' @details
#'
#' The following options are currently known:
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
#' @export
option = function (which, default = NULL) {
    opts = getOption('mod', list())
    opts[[which]] %||% default
}

#' \code{set_options(which = value, ...)} sets one or more {mod} related R
#' options.
#' @param ... one or more key-value pairs in the form \code{\var{key} =
#' \var{value}}.
#' @rdname options
#' @export
set_options = function (...) {
    opts = getOption('mod', list())
    args = list(...)
    opts[names(args)] = args
    options(mod = opts)
}

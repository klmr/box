#' An alternative module system for R
#'
#' Use \code{mod::use(prefix/mod)} to import a module, or \code{mod::use(pkg)}
#' to import a package. Fully qualified names are supported for nested modules,
#' reminiscent of module systems in many other modern languages.
#'
#' @section Import:
#'
#' \itemize{
#'  \item \code{\link{option}}
#'  \item \code{\link{set_options}}
#'  \item \code{\link{use}}
#' }
#'
#' @section Writing modules:
#'
#' Infrastructure and utility functions that are mainly used inside modules.
#'
#' \itemize{
#'  \item \code{\link{file}}
#'  \item \code{\link{name}}
#'  \item \code{register_s3_method}
#' }
#'
#' @section Interactive use:
#'
#' Functions for use in interactive sessions and for testing.
#'
#' \itemize{
#'  \item \code{\link{help}}
#'  \item \code{\link{reload}}
#'  \item \code{\link{set_script_path}}
#'  \item \code{\link{unload}}
#' }
#'
#' @name mod
#' @docType package
#' @importFrom stats setNames
#' @importFrom utils lsf.str
NULL

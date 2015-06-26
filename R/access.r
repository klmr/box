#' Access an object inside a module
#' @usage
#' module$object
#' @param module the module object
#' @param object the name of the object
#' @return Unlike the default \code{$} operator in R, access non-existent
#' objects in modules yields an error rather than returning \code{NULL}.
#' @export
`$.module` = function (module, object) {
    get(object, envir = module, inherits = FALSE)
}

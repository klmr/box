#' @export
`$.module` = function (module, object) {
    get(object, envir = module, inherits = FALSE)
}

#' @export
global_path = pod:::mod_search_path(environment())

#' @export
path_in_fun = function () {
    pod:::mod_search_path(environment())
}

#' @export
path_in_nested_fun = function () {
    f = function () {
        pod:::mod_search_path(environment())
    }
    f()
}

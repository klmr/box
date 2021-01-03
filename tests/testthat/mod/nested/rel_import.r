#' @export
global_path = xyz:::mod_search_path(environment())

#' @export
path_in_fun = function () {
    xyz:::mod_search_path(environment())
}

#' @export
path_in_nested_fun = function () {
    f = function () {
        xyz:::mod_search_path(environment())
    }
    f()
}

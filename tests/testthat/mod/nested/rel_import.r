#' @export
global_path = box:::mod_search_path(environment())

#' @export
path_in_fun = function () {
    box:::mod_search_path(environment())
}

#' @export
path_in_nested_fun = function () {
    f = function () {
        box:::mod_search_path(environment())
    }
    f()
}

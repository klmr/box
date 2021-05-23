box::use(utils[tail])

#' @export
global_path = tail(box:::mod_search_path(environment()), 1L)

#' @export
path_in_fun = function () {
    tail(box:::mod_search_path(environment()), 1L)
}

#' @export
path_in_nested_fun = function () {
    f = function () {
        tail(box:::mod_search_path(environment()), 1L)
    }
    f()
}

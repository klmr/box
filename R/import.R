#' @export
import = function (module, attach = TRUE) {
    stopifnot(is(substitute(module), 'name'))
    module_path = try(find_module(substitute(module)), silent = TRUE)

    if (is(module_path, 'try-error'))
        stop(attr(module_path, 'condition')$message)
}

#' @export
unload = function (module)
    NULL

#' @export
reload = function (module)
    NULL

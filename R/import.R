#' Import a module into the current scope
#'
#' \code{module = import(module)} imports a specified module and makes its code
#' available via the environment-like object it returns.
#'
#' @param module an identifier specifying the full module path
#' @param attach NOT IMPLEMENTED
#' @export
import = function (module, attach = TRUE) {
    module = substitute(module)
    stopifnot(is(module, 'name'))
    module_path = try(find_module(module), silent = TRUE)

    if (is(module_path, 'try-error'))
        stop(attr(module_path, 'condition')$message)

    if (is_module_loaded(module))
        return(invisible())
}

.loaded_modules = c()

is_module_loaded = function (module)
    as.character(module) %in% .loaded_modules

mark_module_loaded = function (module)
    '.loaded_modules' <<- c(.loaded_modules, as.character(module))

#' @export
unload = function (module)
    NULL

#' @export
reload = function (module)
    NULL

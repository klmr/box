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

    if (is_module_loaded(module_path))
        return(invisible(get_loaded_module(module_path)))

    # The parent_env contains meta-information about the imported module.
    # This is convenient, since we can also use it to hold the `module_path`
    # variable which we subsequently access inside the `local` block.
    parent_env = list2env(list(name = as.character(module),
                               module_path = module_path),
                          parent = globalenv())
    module_env = new.env(parent = parent_env)
    class(module_env) = c('module', class(module_env))
    local(source(module_path, chdir = TRUE, local = TRUE), envir = module_env)

    mark_module_loaded(module_env)
    invisible(module_env)
}

#' Environment of loaded modules
#'
#' Each module is stored as an environment inside \code{.loaded_modules} with
#' the module’s code location path as its identifier. The path rather than the
#' module name is used because module names are not unique: two modules called
#' \code{a} can exist nested inside modules \code{b} and \code{c}, respectively.
#' Yet these may be loaded at the same time and need to be distinguished.
.loaded_modules = new.env()

is_module_loaded = function (module_path)
    exists(module_path, envir = .loaded_modules)

mark_module_loaded = function (module_env) {
    assign(module_path(module_env), module_env, envir = .loaded_modules)
}

get_loaded_module = function (module_path)
    get(module_path, envir = .loaded_modules)

module_path = function (module_env)
    parent.env(module_env)$module_path

#' @export
unload = function (module)
    NULL

#' @export
reload = function (module)
    NULL

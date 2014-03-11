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

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

mark_module_loaded = function (module_env)
    assign(module_path(module_env), module_env, envir = .loaded_modules)

get_loaded_module = function (module_path)
    get(module_path, envir = .loaded_modules)

module_path = function (module_env)
    parent.env(module_env)$module_path

#' Get a module’s name
#'
#' @param module_env a module environment (default: current module)
#' @return A character string containing the name of the module or \code{NULL}
#'  if called from outside a module.
#' @note A module’s name is the fully qualified name it was first imported with.
#' If the same module is subsequently imported using another qualified name
#' (from within the same package, say, and hence truncated), the module name
#' does not reflect that.
#' This function approximates Python’s magic variable \code{__name__}, and can
#' be used similarly to test whether a module was loaded via \code{import} or
#' invoked directly.
#' @export
module_name = function (module_env = parent.frame())
    if (is(module_env, 'module')) parent.env(module_env)$name else NULL

#' Import a module into the current scope
#'
#' \code{module = import(module)} imports a specified module and makes its code
#' available via the environment-like object it returns.
#'
#' @param module an identifier specifying the full module path
#' @param attach if \code{TRUE}, attach the newly loaded module to the object
#'      search path
#' @export
import = function (module, attach = FALSE) {
    module = substitute(module)
    stopifnot(is(module, 'name'))
    module_path = try(find_module(module), silent = TRUE)

    if (is(module_path, 'try-error'))
        stop(attr(module_path, 'condition')$message)

    if (is_module_loaded(module_path))
        return(invisible(get_loaded_module(module_path)))

    invisible(do_import(as.character(module), module_path))
}

do_import = function (module_name, module_path) {
    # The namespace contains a module’s content. This schema is very much like
    # R package organisation, minus, for now, the `import:` part.
    # A good resource for this is:
    # <http://obeautifulcode.com/R/How-R-Searches-And-Finds-Stuff/>
    namespace = structure(new.env(parent = .BaseNamespaceEnv),
                          name = paste('namespace', module_name, sep = ':'),
                          path = module_path,
                          class = c('namespace', 'environment'))
    local(source(attr(environment(), 'path'), chdir = TRUE, local = TRUE),
          envir = namespace)
    #' @TODO The parent environment of the module should be the next item in the
    #' search list, I think – like for packages.
    exported_functions = lsf.str(namespace)
    module_env = structure(list2env(sapply(exported_functions,
                                           get, envir = namespace)),
                           name = paste('module', module_name, sep = ':'),
                           path = module_path,
                           class = c('module', 'environment'))
    cache_module(module_env)
    module_env
}

#' Unload a given module
#'
#' Unset the module variable that is being passed as a parameter, and remove the
#' loaded module from cache.
#' @param module reference to the module which should be unloaded
#' @note Any other references to the loaded modules remain unchanged, and will
#' still work. However, subsequently importing the module again will reload its
#' source files, which would not have happened without \code{unload}.
#' Unloading modules is primarily useful for testing during development, and
#' should not be used in production code.
#' @export
unload = function (module) {
    module_ref = as.character(substitute(module))
    rm(list = module_path(module), envir = .loaded_modules)
    # unset the module reference in its scope, i.e. the caller’s environment or
    # some parent thereof.
    rm(list = module_ref, envir = parent.frame(), inherits = TRUE)
}

#' Reload a given module
#'
#' Remove the loaded module from the cache, forcing a reload. The newly reloaded
#' module is assigned to the module reference in the calling scope.
#' @param module reference to the module which should be unloaded
#' @note Any other references to the loaded modules remain unchanged, and will
#' still work. Reloading modules is primarily useful for testing during
#' development, and should not be used in production code.
#' @export
reload = function (module) {
    module_ref = as.character(substitute(module))
    module_path = module_path(module)
    module_name = module_name(module)
    rm(list = module_path, envir = .loaded_modules)
    #' @TODO Once we have `attach`, need also to take care of the search path
    #' and whatnot.
    assign(module_ref, do_import(module_name, module_path),
           envir = parent.frame(), inherits = TRUE)
}

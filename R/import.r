#' Import a module into the current scope
#'
#' \code{module = import(module)} imports a specified module and makes its code
#' available via the environment-like object it returns.
#'
#' @param module an identifier specifying the full module path
#' @param attach if \code{TRUE}, attach the newly loaded module to the object
#'      search path (see \code{Details})
#' @return the loaded module environment (invisible)
#'
#' @details Modules are loaded in an isolated environment which is returned, and
#' optionally attached to the object search path of the current scope (if
#' argument \code{attach} is \code{TRUE}).
#' \code{attach} defaults to \code{FALSE}. However, in interactive code it is
#' often helpful to attach packages by default. Therefore, in interactive code
#' invoked directly from the terminal only (i.e. not within modules),
#' \code{attach} defaults to the value of \code{options('import.attach')}, which
#' can be set to \code{TRUE} or \code{FALSE} depending on the user’s preference.
#'
#' Modules are searched in the module search path \code{options('import.path')}.
#' This is a vector of paths to consider, from the highest to the lowest
#' priority. The current directory is \emph{always} considered first. That is,
#' if a file \code{a.r} exists both in the current directory and in a module
#' search path, the local file \code{./a.r} will be loaded.
#'
#' Module names can be fully qualified to refer to nested paths. See
#' \code{Examples}.
#'
#' @note Unlike for packages, attaching happens \emph{locally}: if
#' \code{import} is executed in the global environment, the effect is the same.
#' Otherwise, the imported module is inserted as the parent of the current
#' \code{environment()}. When used (globally) \emph{inside} a module, the newly
#' imported module is only available inside the module’s search path, not
#' outside it (nor in other modules which might be loaded).
#'
#' @examples
#' # `a.r` is a file in the local directory containing a function `f`.
#' a = import(a)
#' a$f()
#'
#' # b/c.r is a file in path `b`, containing a function `g`.
#' import(b.c, attach = TRUE)
#' g() # No module name qualification necessary
#'
#' @seealso \code{unload}
#' @seealso \code{reload}
#' @seealso \code{module_name}
#' @export
import = function (module, attach) {
    module = substitute(module)
    stopifnot(inherits(module, 'name'))

    if (missing(attach)) {
        attach = if (interactive() && is.null(module_name()))
            getOption('import.attach', FALSE)
        else
            FALSE
    }

    stopifnot(class(attach) == 'logical' && length(attach) == 1)

    module_path = try(find_module(module), silent = TRUE)

    if (inherits(module_path, 'try-error'))
        stop(attr(module_path, 'condition')$message)

    mod_ns = if (is_module_loaded(module_path))
        get_loaded_module(module_path)
    else
        do_import(as.character(module), module_path)

    module_parent = parent.frame()
    mod_env = exhibit_namespace(mod_ns, as.character(module), module_parent)

    if (attach) {
        if (identical(module_parent, .GlobalEnv))
            attach(mod_env, name = environmentName(mod_env))
        else
            parent.env(module_parent) = mod_env
    }

    invisible(mod_env)
}

do_import = function (module_name, module_path) {
    # The namespace contains a module’s content. This schema is very much like
    # R package organisation.
    # A good resource for this is:
    # <http://obeautifulcode.com/R/How-R-Searches-And-Finds-Stuff/>
    namespace = structure(new.env(parent = .BaseNamespaceEnv),
                          name = paste('namespace', module_name, sep = ':'),
                          path = module_path,
                          class = c('namespace', 'environment'))
    local(source(attr(environment(), 'path'), chdir = TRUE, local = TRUE),
          envir = namespace)
    cache_module(namespace)
    namespace
}

exhibit_namespace = function (namespace, name, parent) {
    exported_functions = lsf.str(namespace)
    # Skip one parent environment because this module is hooked into the chain
    # between the calling environment and its ancestor, thus sitting in its
    # local object search path.
    structure(list2env(sapply(exported_functions, get, envir = namespace),
                       parent = parent.env(parent)),
              name = paste('module', name, sep = ':'),
              path = module_path(namespace),
              class = c('module', 'environment'))
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
#'
#' \code{unload} does not currently detach environments.
#' @seealso \code{import}
#' @seealso \code{reload}
#' @export
unload = function (module) {
    stopifnot(inherits(module, 'module'))
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
#'
#' \code{reload} does not work correctly with attached environments.
#' @seealso \code{import}
#' @seealso \code{unload}
#' @export
reload = function (module) {
    stopifnot(inherits(module, 'module'))
    module_ref = as.character(substitute(module))
    module_path = module_path(module)
    module_name = module_name(module)
    rm(list = module_path, envir = .loaded_modules)
    #' @TODO Once we have `attach`, need also to take care of the search path
    #' and whatnot.
    mod_ns = do_import(module_name, module_path)
    module_parent = parent.frame()
    mod_env = exhibit_namespace(mod_ns, module_ref, module_parent)
    assign(module_ref, mod_env, envir = module_parent, inherits = TRUE)
}

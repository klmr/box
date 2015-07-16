#' Import a module into the current scope
#'
#' \code{module = import('module')} imports a specified module and makes its
#' code available via the environment-like object it returns.
#'
#' @param module a character string specifying the full module path
#' @param attach either a boolean or a  character vector. If \code{TRUE}, attach
#'  the newly loaded module to the object search path (see \code{Details}).
#'  Alternatively, if a character vector is given, attach only the listed names.
#' @param attach_operators if \code{TRUE}, attach operators of module to the
#'  object search path, even if \code{attach} is \code{FALSE}
#' @param doc boolean specifying whether to load the module’s documentation (see
#'  \code{Details})
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
#' \code{attach_operators} causes \emph{operators} to be attached by default,
#' because operators can only be invoked in R if they re found in the search
#' path. Not attaching them therefore drastically limits a module’s usefulness.
#'
#' \code{doc} loads the module’s documentation, specified as roxygen comments.
#' It defaults to \code{TRUE} in interactive mode and to \code{FALSE} otherwise.
#'
#' Modules are searched in the module search path \code{options('import.path')}.
#' This is a vector of paths to consider, from the highest to the lowest
#' priority. The current directory is \emph{always} considered last. That is,
#' if a file \code{a.r} exists both in the current directory and in a module
#' search path, the local file \code{./a.r} will not be loaded, unless the
#' import is explicitly specified as \code{import('./a')}.
#'
#' Module names can be fully qualified to refer to nested paths. See
#' \code{Examples}.
#'
#' Module source code files are assumed to be encoded in UTF-8 without BOM.
#' Ensure that this is the case when using an extended character set.
#'
#' @note Unlike for \code{\link{library}}, attaching happens \emph{locally}: if
#' \code{import} is executed in the global environment, the effect is the same.
#' Otherwise, the imported module is inserted as the parent of the current
#' \code{environment()}. When used (globally) \emph{inside} a module, the newly
#' imported module is only available inside the module’s search path, not
#' outside it (nor in other modules which might be loaded).
#'
#' @examples
#' \dontrun{
#' # `a.r` is a file in the local directory containing a function `f`.
#' a = import('a')
#' a$f()
#'
#' # b/c.r is a file in path `b`, containing functions `f` and `g`.
#' import('b/c', attach = 'f')
#' # No module name qualification necessary
#' f()
#' g() # Error: could not find function "g"
#'
#' import('b/c', attach = TRUE)
#' f()
#' g()
#' }
#' @seealso \code{unload}
#' @seealso \code{reload}
#' @seealso \code{module_name}
#' @seealso \code{module_help}
#' @export
import = function (module, attach, attach_operators = TRUE, doc) {
    stopifnot(inherits(module, 'character'))

    if (missing(attach)) {
        attach = if (interactive() && is.null(module_name()))
            getOption('import.attach', FALSE)
        else
            FALSE
    }

    stopifnot(class(attach) == 'logical' && length(attach) == 1 ||
              class(attach) == 'character')

    if (is.character(attach)) {
        export_list = attach
        attach = TRUE
    }
    else
        export_list = NULL

    if (missing(doc))
        doc = interactive()

    module_path = try(find_module(module), silent = TRUE)

    if (inherits(module_path, 'try-error'))
        stop(attr(module_path, 'condition')$message)

    containing_modules = module_init_files(module, module_path)
    mapply(do_import, names(containing_modules), containing_modules,
           rep(doc, length(containing_modules)))

    mod_ns = do_import(module, module_path, doc)
    module_parent = parent.frame()
    mod_env = exhibit_namespace(mod_ns, module, module_parent,
                                export_list)

    attached_module = if (attach)
        mod_env
    else if (attach_operators)
        export_operators(mod_env, module_parent, module)
    else
        NULL

    if (! is.null(attached_module)) {
        # The following distinction is necessary because R segfaults if we try
        # to change `parent.env(.GlobalEnv)`. More info:
        # http://stackoverflow.com/q/22790484/1968
        if (identical(module_parent, .GlobalEnv)) {
            attach(attached_module, name = environmentName(attached_module))
            attr(mod_env, 'attached') = environmentName(attached_module)
        }
        else
            parent.env(module_parent) = attached_module
    }

    attr(mod_env, 'call') = match.call()
    lockEnvironment(mod_env, bindings = TRUE)
    invisible(mod_env)
}

do_import = function (module_name, module_path, doc) {
    if (is_module_loaded(module_path))
        return(get_loaded_module(module_path))

    # Environment with helper functions which are only available when loading a
    # module via `import`, and are not otherwise exported by the package.
    helper_env = list2env(list(export_submodule = export_submodule),
                          parent = .BaseNamespaceEnv)

    # The namespace contains a module’s content. This schema is very much like
    # R package organisation.
    # A good resource for this is:
    # <http://obeautifulcode.com/R/How-R-Searches-And-Finds-Stuff/>
    namespace = structure(new.env(parent = helper_env),
                          name = paste('namespace', module_name, sep = ':'),
                          path = module_path,
                          class = c('namespace', 'environment'))

    # First cache the (still empty) namespace, then source code into it. This is
    # necessary to allow circular imports.
    cache_module(namespace)
    # If loading fails due to an error inside the module (i.e. `parse` or `eval`
    # will fail), we unload the module again.
    on.exit(uncache_module(namespace))

    # R, Windows and Unicode don’t play together. `source` does not work here.
    # See http://developer.r-project.org/Encodings_and_R.html and
    # http://stackoverflow.com/q/5031630/1968 for a discussion of this.
    eval(parse(module_path, encoding = 'UTF-8'), envir = namespace)

    make_S3_methods_known(namespace)

    if (doc)
        attr(namespace, 'doc') = parse_documentation(namespace)

    # No error occured — prevent unloading.
    on.exit()
    namespace
}

exhibit_namespace = function (namespace, name, parent, export_list) {
    if (is.null(export_list))
        export_list = ls(namespace)
    else {
        # Verify correctness.
        exist = vapply(export_list, exists, logical(1), envir = namespace)
        if (! all(exist))
            stop(sprintf('Non-existent function(s) (%s) specified for import',
                         paste(export_list[! exist], collapse = ', ')))
    }

    # Skip one parent environment because this module is hooked into the chain
    # between the calling environment and its ancestor, thus sitting in its
    # local object search path.
    structure(list2env(mget(export_list, envir = namespace),
                       parent = parent.env(parent)),
              name = paste('module', name, sep = ':'),
              path = module_path(namespace),
              doc = attr(namespace, 'doc'),
              class = c('module', 'environment'))
}

#' Copy a module’s operators into a separate environment
#'
#' This function is used to create an attachable environment containing only the
#' module’s operators, as these would otherwise not be readily usable.
#' @param environment the module environment
#' @param parent the parent environment of the calling code, to determine how to
#'  chain the environments properly
#' @param module_name the name of the module
#' @return A new environment containing the operators of the module.
#' @note This function expects the module \emph{environment} rather than the
#' \emph{namespace}. This is important because, for package modules, we only
#' want to expose exported operators, and not all exported operators are visible
#' inside the namespace (see, for example, \code{\link[dplyr]{\%>\%}}, which is
#' imported from the package “magrittr”).
export_operators = function (environment, parent, module_name) {
    ops = c('+', '-', '*', '/', '^', '**', '&', '|', ':', '::', ':::', '$',
            '$<-', '=', '<-', '<<-', '==', '<', '<=', '>', '>=', '!=', '~',
            '&&', '||', '!', '?', '@', '@<-', ':=')

    is_predefined = function (f) f %in% ops

    is_op = function (f) {
        # `.` delimits an S3 method name, but only when not inside `%…%`.
        prefix = regmatches(f, regexpr('^[^.]+|(%[^%]*%)', f))
        is_predefined(prefix) || grepl('^%.*%$', prefix)
    }

    operators = Filter(is_op, lsf.str(environment))

    if (length(operators) == 0)
        return()

    # Skip one parent environment because this module is hooked into the chain
    # between the calling environment and its ancestor, thus sitting in its
    # local object search path.
    structure(list2env(sapply(operators, get, envir = environment),
                       parent = parent.env(parent)),
              name = paste('operators', module_name, sep = ':'),
              path = module_path(environment),
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
#' \code{unload} comes with a few restrictions. It attempts to detach itself
#' if it was previously attached. This only works if it is called in the same
#' scope as the original \code{import}.
#' @seealso \code{import}
#' @seealso \code{reload}
#' @export
unload = function (module) {
    stopifnot(inherits(module, 'module'))
    module_ref = as.character(substitute(module))
    uncache_module(module)
    attached = attr(module, 'attached')
    if (! is.null(attached))
        detach(attached, character.only = TRUE)
    # Unset the module reference in its scope, i.e. the caller’s environment or
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
#' \code{reload} comes with a few restrictions. It attempts to re-attach itself
#' in parts or whole if it was previously attached in parts or whole. This only
#' works if it is called in the same scope as the original \code{import}.
#' @seealso \code{import}
#' @seealso \code{unload}
#' @export
reload = function (module) {
    stopifnot(inherits(module, 'module'))
    module_ref = as.character(substitute(module))
    module_parent = parent.frame()
    # Execute in parent scope, since `unload` deletes the scope’s reference to
    # the module.
    eval.parent(call('unload', as.name(module_ref)))
    # Use `eval` to replicate the exact call being made to `import`.
    mod_env = eval.parent(attr(module, 'call'))
    assign(module_ref, mod_env, envir = module_parent, inherits = TRUE)
}

#' @export
print.module = function (x, ...) {
    cat(sprintf('<%s>\n', attr(x, 'name')))
    invisible(x)
}

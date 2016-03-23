#' Environment of loaded modules
#'
#' Each module is stored as an environment inside \code{loaded_modules} with
#' the module’s code location path as its identifier. The path rather than the
#' module name is used because module names are not unique: two modules called
#' \code{a} can exist nested inside modules \code{b} and \code{c}, respectively.
#' Yet these may be loaded at the same time and need to be distinguished.
loaded_modules = new.env(parent = emptyenv())

#' 
#' \code{is_module_loaded} tests whether a module is already lodaded
#' @param module_path fully resolved module path
#' @rdname loaded_modules
is_module_loaded = function (module_path)
    exists(module_path, envir = loaded_modules, inherits = FALSE)

#' 
#' \code{cache_module} caches a module namespace and marks the module as loaded.
#' @param module_ns module namespace environment
#' @rdname loaded_modules
cache_module = function (module_ns)
    assign(module_path(module_ns), module_ns, envir = loaded_modules)

#' 
#' \code{uncache_module} removes a module namespace from the cache, unloading
#' the module from memory.
#' @rdname loaded_modules
uncache_module = function (module_ns)
    rm(list = module_path(module_ns), envir = loaded_modules)

#' 
#' \code{clear_modules_cache} unloads all loaded modules from the cache.
#' @rdname loaded_modules
clear_modules_cache = function ()
    rm(list = ls(envir = loaded_modules, all.names = TRUE),
       envir = loaded_modules)

#' 
#' \code{get_loaded_module} returns a loaded module, identified by its path,
#' from cache.
#' @rdname loaded_modules
get_loaded_module = function (module_path)
    get(module_path, envir = loaded_modules, inherits = FALSE)

#' Module attributes
#'
#' \code{module_attributes} returns or assigns the attributes associated with
#' a module.
#' @param module a module
module_attributes = function (module)
    get('.__module__.', module, mode = 'environment', inherits = TRUE)

#' 
#' @param value the attributes to assign
#' @rdname module_attributes
`module_attributes<-` = function (module, value) {
    module$.__module__. = value
    module
}

#' 
#' \code{module_attr} reads or assigns a single attribute associated with a
#' module.
#' @param attr the attribute name
#' @rdname module_attributes
module_attr = function (module, attr)
    get(attr, module_attributes(module))

#' 
#' @rdname module_attributes
`module_attr<-` = function (module, attr, value) {
    if (! exists('.__module__.', module, mode = 'environment', inherits = FALSE))
        module_attributes(module) = new.env(parent = emptyenv())
    module$.__module__.[[attr]] = value
    module
}

#' Get a module’s path
#'
#' @param module a module environment or namespace
#' @return A character string containing the module’s full path.
module_path = function (module)
    module_attr(module, 'path')

#' Get a module’s base directory
#'
#' @param module a module environment or namespace
#' @return A character string containing the module’s base directory,
#'  or the current working directory if not invoked on a module.
module_base_path = function (module) {
    path = try(module_attr(module, 'path'), silent = TRUE)
    if (inherits(path, 'try-error'))
        normalizePath(script_path(), winslash = '/')
    else
        normalizePath(dirname(path), winslash = '/')
}

#' Set the base path of the script.
#'
#' @param path character string containing the relative or absolute path, or
#' \code{NULL} to reset the path
#'
#' @details
#' \emph{modules} needs to know the base path of the topmost calling R script
#' to find relative import locations. In most cases, it can figure the path out
#' automatically. However, in some cases third party packages load files in such
#' a way that \emph{modules} cannot find out the correct path of the script any
#' more. \code{set_script_path} can be used in these cases to set the script
#' path manually.
#' @export
set_script_path = function (path) {
    if (is.null(path))
        # Use `list = '.'` instead of `.` to work around bug in `R CMD CHECK`,
        # which thinks that `.` refers to a non-existent global symbol.
        rm(list = '.', envir = loaded_modules)
    else
        assign('.', dirname(path), loaded_modules)
}

#' Return an R script’s path
script_path = function () {
    # Take a best guess at a script’s path. The following calling situations are
    # covered:
    #
    # 1. Explicitly via `set_script_path` set script path
    # 2. Inside calling container (knitr, Shiny)
    # 3. Rscript script.r
    # 4. R CMD BATCH script.r
    # 5. Script run interactively (give up, use `getwd()`)

    if (exists('.', envir = loaded_modules, inherits = FALSE))
        return(get('.', envir = loaded_modules, inherits = FALSE))

    if (! is.null((knitr_path = knitr_path())))
        return(knitr_path)

    if (! is.null((shiny_path = shiny_path())))
        return(shiny_path)

    args = commandArgs()

    file_arg = grep('--file=', args)
    if (length(file_arg) != 0)
        return(dirname(sub('--file=', '', args[file_arg])))

    f_arg = grep('-f', args)
    if (length(f_arg) != 0)
        return(dirname(args[f_arg + 1]))

    getwd()
}

knitr_path = function () {
    if (! 'knitr' %in% loadedNamespaces())
        return(NULL)

    knitr_input = suppressWarnings(knitr::current_input(dir = TRUE))
    if (! is.null(knitr_input))
        dirname(knitr_input)
}

shiny_path = function () {
    # Look for `runApp` call somewhere in the call stack.
    frames = sys.frames()
    calls = lapply(sys.calls(), `[[`, 1)
    call_name = function (call)
        if (is.function(call)) '<closure>' else deparse(call)
    call_names = vapply(calls, call_name, character(1))

    target_call = grep('^runApp$', call_names)

    if (length(target_call) == 0)
        return(NULL)

    target_frame = frames[[target_call]]
    namespace_frame = parent.env(target_frame)
    if(isNamespace(namespace_frame) && environmentName(namespace_frame) == 'shiny')
        getwd()
}

#' Get a module’s name
#'
#' @param module a module environment (default: current module)
#' @return A character string containing the name of the module or \code{NULL}
#'  if called from outside a module.
#' @note A module’s name is the name of a module that it was \code{import}ed
#' with. If the same module is subsequently imported using another qualifie
#' name (from within the same package, say, and hence truncated), the module
#' names of the two module instances may differ, even though the same copy of
#' the byte code is used.
#' This function approximates Python’s magic variable \code{__name__}, and can
#' be used similarly to test whether a module was loaded via \code{import} or
#' invoked directly.
#' @examples
#' \dontrun{
#' cat('This code is always executed.\n')
#'
#' if (is.null(module_name())) {
#'     cat('This code is only executed when the module is run
#'         as stand-alone code via Rscript or R CMD BATCH.\n')
#' }
#' }
#' @export
module_name = function (module = parent.frame()) {
    name = try(module_attr(module, 'name'), silent = TRUE)
    if (inherits(name, 'try-error'))
        NULL
    else
        strsplit(name, ':', fixed = TRUE)[[1]][2]
}

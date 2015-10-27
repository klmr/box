#' Environment of loaded modules
#'
#' Each module is stored as an environment inside \code{loaded_modules} with
#' the module’s code location path as its identifier. The path rather than the
#' module name is used because module names are not unique: two modules called
#' \code{a} can exist nested inside modules \code{b} and \code{c}, respectively.
#' Yet these may be loaded at the same time and need to be distinguished.
loaded_modules = new.env()

is_module_loaded = function (module_path)
    exists(module_path, envir = loaded_modules, inherits = FALSE)

cache_module = function (module_ns)
    assign(module_path(module_ns), module_ns, envir = loaded_modules)

uncache_module = function (module_ns)
    rm(list = module_path(module_ns), envir = loaded_modules)

get_loaded_module = function (module_path)
    get(module_path, envir = loaded_modules, inherits = FALSE)

#' Get a module’s path
#'
#' @param module a module environment or namespace
#' @return A character string containing the module’s full path.
module_path = function (module)
    attr(module, 'path')

# FIXME: Maintain registry of meta information for all functions.

#' Get a module’s base directory
#'
#' @param module a module environment or namespace
#' @return A character string containing the module’s base directory,
#'  or the current working directory if not invoked on a module.
module_base_path = function (module)
    UseMethod('module_base_path')

module_base_path.default = function (module) {
    if (identical(module, .GlobalEnv))
        script_path()
    else
        module_base_path(parent.env(module))
}

module_base_path.module = function (module)
    dirname(module_path(module))

module_base_path.namespace = function (module)
    dirname(module_path(module))

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
        rm(., envir = loaded_modules)
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

    if (! is.null({knitr_path = knitr_path()}))
        return(knitr_path)

    if (! is.null({shiny_path = shiny_path()}))
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
module_name = function (module = parent.frame())
    UseMethod('module_name', module)

#' @seealso \code{module_name}
#' @export
module_name.default = function (module = parent.frame()) {
    if (identical(module, .GlobalEnv))
        NULL
    else
        module_name(parent.env(module))
}

#' @seealso \code{module_name}
#' @export
module_name.module = function (module = parent.frame())
    strsplit(attr(module, 'name'), ':', fixed = TRUE)[[1]][2]

#' @seealso \code{module_name}
#' @export
module_name.namespace = function (module = parent.frame())
    strsplit(attr(module, 'name'), ':', fixed = TRUE)[[1]][2]

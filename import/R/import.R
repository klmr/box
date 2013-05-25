#' Import a module into the current R module context.
#'
#'
#' @export
import <- function (.module, .only = NULL, ...) {
    #
    # Parse arguments.
    #

    if (! is.symbol(substitute(.module)))
        stop('`.module` must be an identifier')

    module <- as.character(substitute(.module))
    only <- substitute(.only)
    aliases <- match.call(expand.dots = FALSE)$...

    # `.only` expected format: c(some, identifiers)
    whatError <- '`.only` must be a vector of identifiers, or NULL'

    if (is.null(only) || as.character(only) == 'NULL')
        only <- NULL
    else {
        if (length(only) > 1) {
            if (only[1] != substitute(c()))
                stop(whatError)
            only <- only[-1]
        }

        if (! all(vapply(only, is.symbol, TRUE)))
            stop(whatError)
        only <- symbolToCharacter(only)
    }

    # `.aliases` expected format: a = b, c = d, e = f
    #                         OR: c(a = b)
    # The second form is allowed so that the user can define aliases for the
    # imported names `.module` and `.only`, which would otherwise be impossible
    # because they shadow function arguments.
    aliasError <- '... must be of format `foo = bar, ...` or `c(foo = bar, ...)`'

    if (length(aliases) == 1 && is.call(aliases[[1]]) && aliases[[1]][1] == substitute(c()))
        aliases <- aliases[[1]][-1]

    if (! all(vapply(aliases, is.symbol, TRUE)))
        stop(aliasError)

    aliases <- as.list(aliases)

    invisible(doImport(module, only, aliases))
}

#' @export
export <- function (...) {
    exportNames <- symbolToCharacter(match.call(expand.dots = FALSE)$...)
    theExportNames <<- exportNames
    theExportAllNames <<- length(exportNames) == 0
    invisible(exportNames)
}

#' @export
unload <- function (module) {
}

#' @export
reload <- function (module) {
}

#' @export
moduleSearchPath <- c(
    strsplit(Sys.getenv('R_MODULE_PATH'), ':')[[1]],
    '~/.R/modules')

#' @export
resolveModulePath <- function (module) {
    if (! is.symbol(substitute(module)))
        stop('`module` must be an identifier')

    name <- qualifiedModuleToPath(as.character(substitute(module)))

    for (path in c('.', moduleSearchPath)) {
        putativePath <- file.path(path, name)
        validated <- checkValidModule(putativePath)
        if (! is.null(validated))
            return(validated)
    }

    NULL # Nothing found
}

#' @export
loadedModules <- function ()
    names(theLoadedModulesInfo)

doImport <- function (module, only, aliases) {
    #
    # Find file to import for module based on module search path.
    #

    moduleFile <- resolveModulePath(module)

    if (is.null(moduleFile))
        stop(sprintf("unable to find module %s in path '%s'", module, searchPath))

    #
    # * Source module file(s) in local context
    # * Create module tracking record and hook up to exported environment
    # * Collect exported symbols from `theExportName` and `theExportAllNames`
    # * Copy exported names to exported environment
    # * Link with documentation
    # * (Make remaining names available via `:::` somehow?)
    #
}

symbolToCharacter <- function (symbols)
    # FIXME Surely there is a better way of handling operator names?
    gsub('^`(.*)`$', '\\1', symbols)

checkValidModule <- function (path) {
    paths <- c(paste(path, '.R', sep = ''),
               file.path(path, '_init.R'))
    pathExists <- file.exists(paths)

    if (all(pathExists))
        warning(sprintf("Ambiguous module path; using %s", paths[1]))

    if (any(pathExists))
        paths[pathExists][1]
    else NULL
}

#
# Importing a module adds an environment which contains all the modules' objects
# and additionally adds all those specified in `only` (or all, if none are
# specified) to the search path.
# In addition, a tracking record is created for the import which contains its
# name, file system location and a reference to its environment.
# This is used for unloading and reloading.
#

prepareModule <- function (module, path) {
    name <- paste('module', as.character(substitute(module)), sep = ':')
    modEnv <- attach(module, name = name)
    class(modEnv) <- 'module'
    theLoadedModulesInfo[[name]] <- list(name = name, path = path, env = modEnv)
    modEnv
}

# Performs the transformation 'a.bc.d' => 'a/bc/d'
qualifiedModuleToPath <- function (id)
    do.call(file.path, as.list(strsplit(id, '\\.')[[1]]))

moduleName <- function (module) {
    if (! is.symbol(substitute(module)))
        stop('`module` must be an identifier')

    as.character(substitute(module))
}

theLoadedModulesInfo <- list()
theExportNames <- NULL
theExportAllNames <- FALSE

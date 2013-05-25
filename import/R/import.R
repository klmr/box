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
        only <- as.character(only)
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
    names(loadedModulesInfo)

doImport <- function (module, only, aliases) {
    #
    # Find file to import for module based on module search path.
    #

    moduleFile <- resolveModulePath(module)

    if (is.null(moduleFile))
        stop(sprintf("unable to find module %s in path '%s'", module, searchPath))

    #
    # Create a temporary package for the import file, and load it
    #

    packageDir <- file.path(tempdir(), module)
    #on.exit(unlink(packageDir, recursive = TRUE))
    require(devtools)
    #on.exit(Sys.unsetenv('_R_CHECK_FORCE_SUGGESTS_'))
    #Sys.setenv('_R_CHECK_FORCE_SUGGESTS_' = FALSE)
    # Not using `create` to avoid redundant checks and diagnostic messages
    #devtools::create(packageDir)

    capture.output(suppressMessages(dir.create(packageDir)))
    suppressMessages(dir.create(file.path(packageDir, 'R')))
    suppressMessages(dir.create(file.path(packageDir, 'man')))
    file.copy(moduleFile, file.path(packageDir, 'R'))
    defaults <- list(Package = module,
                     Version = '0.1',
                     License = '',
                     Description = '',
                     Title = module,
                     Author = '',
                     Maintainer = 'Nobody <nobody@example.com>')
    write.dcf(defaults, file.path(packageDir, 'DESCRIPTION'))
    #devtools:::create_package_doc(packageDir, module)
    #capture.output(suppressMessages(devtools::document(packageDir, reload = FALSE)))

    if (! is.null(only)) {
        # TODO Implement restricted imports
        # Create a NAMESPACE file to import only the chosen names
    }

    devtools::load_all(packageDir, quiet = TRUE)

    if (! is.null(aliases)) {
        # TODO Implement aliases
        # Rename all names to be aliased
    }

    packageDir
}

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
    loadedModulesInfo[[name]] <- list(name = name, path = path, env = modEnv)
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

#
# EVERYTHING BELOW THIS LINE IS LEGACY AND WILL BE REMOVED
#


# TODO Implement `as`
# TODO Implement search path handling
# TODO Consolidate metadata (such as imports list, include guard) in imports environment
import <- function (module, imports = NULL, as = NULL) {
    module <- as.character(substitute(module))
    filename <- paste(module, 'R', sep = '.')

    includeGuard <- paste('.INCLUDE', toupper(module), 'R', sep = '_')
    if (exists(includeGuard, envir = topenv()))
        return()

    assign(includeGuard, TRUE, envir = topenv())
    env <- new.env(parent = topenv())
    class(env) <- 'module'
    attr(env, 'name') <- module
    sys.source(filename, chdir = TRUE, envir = env)

    for (name in imports)
        # TODO Issue warning for overwritten objects?
        assign(name, get(name, envir = env), envir = topenv())

    assign(module, env, envir = topenv())
    if (is.null(imports)) ls(envir = env) else imports
}

reload <- function (module, imports = NULL, as = NULL) {
    modName <- environmentName(module)
    includeGuard <- paste('.INCLUDE', toupper(modName), 'R', sep = '_')
    if (exists(includeGuard, envir = topenv()))
        rm(list = includeGuard, envir = topenv())
    do.call(import, list(modName, imports, as))
}

# TODO Purge objects, not only environment & include guard
unload <- function (module) {
    modName <- environmentName(module)
    includeGuard <- paste('.INCLUDE', toupper(modName), 'R', sep = '_')
    if (exists(includeGuard, envir = topenv()))
        rm(list = c(includeGuard, modName), envir = topenv())
}

`::.module` <- function (module, name)
    get(as.character(substitute(name)),
        envir = get(as.character(substitute(module)), envir = topenv()))

`::` <- function (module, name) {
    module <- as.character(substitute(module))
    name <- as.character(substitute(name))
    if (exists(module, envir = topenv()))
        UseMethod('::')
    else
        getExportedValue(module, name)
}

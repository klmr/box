#' Find a module’s source code location
#'
#' @param module expression containing the fully qualified module name
#' @return the full path to the corresponding module source code location. If
#' multiple hits are found, return the one with the highest priority, that is
#' coming earlier in the search path, with the local directory having the
#' highest priority. If no path is found, return \code{NA}.
find_module = function (module) {
    full_name = as.character(module)
    # Prepend '' to ensure that at least one path component exists, otherwise
    # `file.path` will subsequently return an empty vector instead of '' for
    # `candidate_paths`.
    parts = c('', unlist(strsplit(full_name, '\\.')))

    # Use all-but-last parts to construct module source path, last part to
    # determine name of source file.
    prefix = parts[-length(parts)]
    suffix = parts[length(parts)]
    module_path = do.call(file.path, as.list(prefix))
    file_pattern = sprintf('^%s\\.[rR]$', suffix)

    candidate_paths = file.path(import_search_path(), module_path)

    if (! identical(prefix, '')) {
        # Remove those candidates which have no `__init__.r` files in the module
        # name prefix but are nested.

        is_valid_nested = function (path)
            ! is.null(module_init_files(module, path))

        candidate_paths = Filter(is_valid_nested, candidate_paths)
    }

    # For each candidate, try finding a module file. A module file is either
    # `{suffix}.r` or `{suffix}/__init__.r`, preceded by the path prefix.

    find_candidate = function (path) {
        candidate = list.files(path, file_pattern, full.names = TRUE)

        if (length(candidate) == 0)
            list.files(file.path(path, suffix), '^__init__\\.[rR]$',
                       full.names = TRUE)
        else
            candidate
    }

    hits = unlist(lapply(candidate_paths, find_candidate))

    if (length(hits) == 0)
        stop('Unable to load module ', full_name, '; not found in ',
             paste(Map(function (p) sprintf('"%s"', p), import_search_path()),
                   collapse = ', '))

    normalizePath(unname(hits[1]))
}

#' Return a list of paths to a module’s \code{__init__.r} files
#'
#' @param module expression containing the fully qualified module name
#' @param module_name the module’s file path prefix (see \code{Details})
#' @return a vector of paths to the module’s \code{__init__.r} files, in the
#' order in which they need to be executed, or \code{NULL} if the arguments do
#' not resolve to a valid nested module (i.e. not all of the path components
#' which form the qualified module name contain a \code{__init__.r} file).
#' @details The \code{module_name} is the fully qualified module path, but
#' without the trailing module file (either \code{x.r} or \code{x/__init__.r}).
module_init_files = function (module, module_path) {
    full_name = as.character(module)
    module_parts = unlist(strsplit(full_name, '\\.'))
    module_parts = module_parts[-length(module_parts)]

    path_parts = unlist(strsplit(module_path, '/'))
    path_prefix_length = length(path_parts) - length(module_parts)
    base_path = do.call(file.path, as.list(path_parts[1 : path_prefix_length]))

    # Find the `__init__.r` files in all path components of `module_parts`.
    # Any `__init__.r` files *upstream* of this path must be disregarded, e.g.
    # for the following path
    #
    #   + a/
    #   +-+ b/
    #   | +-> __init__.r
    #   +-> __init__.r
    #
    # and code
    #
    #   options(import.path = 'a')
    #   import(b)
    #
    # only `a/b/__init__.r` gets executed, not `a/__init__.r`.

    build_prefix = function (i)
        list.files(do.call(file.path,
                           as.list(c(base_path, module_parts[1 : i]))),
                   pattern = '^__init__\\.[rR]$', full.names = TRUE)

    all_prefixes = unlist(sapply(seq_along(module_parts), build_prefix))

    if (length(all_prefixes) != length(module_parts))
        NULL
    else
        all_prefixes
}

#' Return the import module search path
#'
#' @note The search paths are ordered from highest to lowest priority.
#' \code{getwd()} always has the highest priority.
#'
#' There are two ways of modifying the module search path: by default,
#' \code{options('import.path')} specifies the search path. If and only if that
#' is unset, R also considers the environment variable \code{R_IMPORT_PATH}.
import_search_path = function () {
    environment = Sys.getenv('R_IMPORT_PATH')
    if (identical(environment, ''))
        environment = NULL
    c(getwd(), getOption('import.path', environment))
}

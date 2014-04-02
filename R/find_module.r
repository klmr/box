#' Find a module’s source code location
#'
#' @param module Expression containing the fully qualified module name
#' @return The full path to the corresponding module source code location. If
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
    module_path = do.call(file.path, as.list(parts[-length(parts)]))
    file_pattern = sprintf('^%s\\.[rR]', parts[length(parts)])

    candidate_paths = file.path(import_search_path(), module_path)

    # `list.files` accepts multiple input paths, but it sorts the returned files
    # alphabetically, and we thus lose information about the priority, thus we
    #' vectorise manually.
    hits = unlist(Vectorize(list.files)(candidate_paths, file_pattern,
                                        full.names = TRUE))

    if (length(hits) == 0)
        stop('Unable to load module ', full_name, '; not found in ',
             paste(Map(function (p) sprintf('"%s"', p), import_search_path()),
                   collapse = ', '))

    normalizePath(unname(hits[1]))
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

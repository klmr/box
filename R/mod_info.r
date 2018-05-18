#' Information about a physical module or package
#'
#' A \code{mod_info} represents an existing, installed module or package and its
#' runtime physical location (usually in the file system).
#' @keywords internal
mod_info = function (spec, source_path, parent_mods) {
    structure(as.list(environment()), class = 'mod_info')
}

print.mod_info = function (x, ...) {
    cat(as.character(x, ...), '\n', sep = '')
    invisible(x)
}

as.character.mod_info = function (x, ...) {
    parents = if (length(x$parent_mods) == 0L) '' else {
        parent_paths = paste(
            sprintf('\x1B[33m%s\x1B[0m', x$parent_mods),
            collapse = '\n    '
        )
        sprintf('\n  parents:\n    %s', parent_paths)
    }
    sprintf(
        '%s:\n  path: \x1B[33m%s\x1B[0m%s',
        as.character(x$spec, ...), x$source_path, parents
    )
}

is_absolute = function (spec) {
    spec$prefix[1] %in% c('.', '..')
}

find_mod = function (spec) {
    if (is_absolute(spec)) find_local_mod(spec) else find_global_mod(spec)
}

find_local_mod = function (spec) {
    find_in_path(spec, calling_mod_path())
}

find_global_mod = function (spec) {
    # In the future, this may be augmented by pluggable ways of loading modules.
    find_in_path(spec, mod_search_path())
}

find_in_path = function (spec, base_paths) {
    mod_path_prefix = merge_path(spec$prefix)
    ext = c('.r', '.R')
    # TODO: Write unit test that ensures the module is found in the correct
    # order of preference of paths, when multiple possibilities exist.
    simple_mod = file.path(mod_path_prefix, paste0(spec$name, ext))
    nested_mod = file.path(mod_path_prefix, spec$name, paste0('__init__', ext))
    candidates = lapply(base_paths, file.path, c(simple_mod, nested_mod))
    hits = lapply(candidates, file.exists)
    which_base = which(vapply(hits, any, logical(1L)))[1L]

    if (is.na(which_base)) {
        stop(
            'Unable to load module ', sQuote(mod_name(spec)), '; not found in ',
            paste(sQuote(base_paths), collapse = ', ')
        )
    }

    path = candidates[[which_base]][hits[[which_base]]][1L]
    base_path = base_paths[which_base]
    mod_info(spec, normalizePath(path), mod_init_files(path, base_path))
}

#' Find the `__init__.r` files in all path components of `path`.
#'
#' \code{mod_init_files(path, base_path)` finds all init files for a module file
#' given by \code{path}. Any `__init__.r` files \emph{upstream} of this path
#' must be disregarded; e.g. for the following path
#'
#'   a/
#'   ├── b/
#'   │   ├── __init__.r
#'   │   └── c/
#'   │       ├── __init__.r
#'   │       └── d.r
#'   └── __init__.r
#'
#' and code
#'
#'   options(mod.path = 'a')
#'   mod::use(b/c/d)
#'
#' only `a/b/c/__init__.r` and `a/b/__init__.r` get executed, not
#' `a/__init__.r`.
#' @param path the path to the module file.
#' @param base_path the base path corresponding to the module path, such that
#' \code{path} starts with \code{base_path}
#' @keywords internal
mod_init_files = function (path, base_path) {
    init_files = c('__init__.r', '__init__.R')

    remove_mod_part = function (components) {
        mod_particle = if (tail(components, 1L) %in% init_files) 2L else 1L
        head(components, - mod_particle)
    }

    base_path_length = length(split_path(base_path))
    components = tail(remove_mod_part(split_path(path)), - base_path_length)
    mod_parents = lapply(seq_along(components), head, x = components)
    parent_mod_suffixes = vapply(mod_parents, merge_path, character(1L))
    parent_mod_paths = file.path(base_path, parent_mod_suffixes)
    candidate_paths = lapply(parent_mod_paths, file.path, init_files)

    path_has_init = lapply(candidate_paths, file.exists)
    tail = tail_run(vapply(path_has_init, any, logical(1L)))
    actual_init_files = Map(`[`, candidate_paths[tail], path_has_init[tail])
    # Both spellings of the init file might exist. Furthermore, on case
    # insensitive file systems (macOS, Windows), both init files are found;
    # filter to only report a single one each.
    init_paths = vapply(actual_init_files, head, character(1L), 1L)
    normalizePath(init_paths)
}

#' Toggle intermittent \code{TRUE} values before the tail
#'
#' \code{tail_run(x)} transforms a vector of logicals by setting all values
#' before the “tail” to \code{FALSE}. The tail is a sequence of uninterrupted
#' \code{TRUE} values until the end.
#'
#' @param x a logical vector
#' @param Returns a logical vector \code{c(rep(FALSE, n), rep(TRUE, m)} the same
#' length as \code{x}, where \code{m} is the length of the tail of uninterrupted
#' \code{TRUE} values in \code{x}, and \code{n = length(x) - m}.
#' @keywords internal
tail_run = function (x) {
    as.logical(rev(cumprod(rev(x))))
}

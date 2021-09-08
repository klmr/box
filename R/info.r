#' Information about a physical module or package
#'
#' A \code{mod_info} represents an existing, installed module and its runtime
#' physical location (usually in the file system).
#' @param mod_spec a \code{mod_spec}.
#' @param source_path character string full path to the physical module
#' location.
#' @return \code{mod_info} and \code{pkg_info} return a structure representing
#' the module/package information for the given specification/source location.
#' @keywords internal
#' @name info
mod_info = function (spec, source_path) {
    structure(
        list(name = spec$name, source_path = source_path),
        class = c('box$mod_info', 'box$info')
    )
}

#' A \code{pkg_info} represents an existing, installed package.
#' @param pkg_spec a \code{pkg_spec}
#' @keywords internal
#' @name info
pkg_info = function (spec) {
    structure(list(name = spec$name), class = c('box$pkg_info', 'box$info'))
}

#' @export
`print.box$info` = function (x, ...) {
    cat(as.character(x, ...), '\n', sep = '')
    invisible(x)
}

#' @export
`as.character.box$mod_info` = function (x, ...) {
    fmt('<mod_info: \x1B[33m{x$name}\x1B[0m at \x1B[33m{x$source_path}\x1B[0m>')
}

#' @export
`as.character.box$pkg_info` = function (x, ...) {
    path = getNamespaceInfo(x$name, 'path')
    fmt('<mod_info: \x1B[33m{path}\x1B[0m>')
}

is_absolute = function (spec) {
    spec$prefix[1L] %in% c('.', '..')
}

find_mod = function (spec, caller) {
    UseMethod('find_mod')
}

`find_mod.box$mod_spec` = function (spec, caller) {
    if (is_absolute(spec)) find_local_mod(spec, caller) else find_global_mod(spec, caller)
}

`find_mod.box$pkg_spec` = function (spec, caller) {
    pkg_info(spec)
}

find_local_mod = function (spec, caller) {
    find_in_path(spec, calling_mod_path(caller))
}

find_global_mod = function (spec, caller) {
    # In the future, this may be augmented by pluggable ways of loading modules.
    find_in_path(spec, mod_search_path(caller))
}

#' Find a module’s source location
#'
#' @param spec a \code{mod_spec}.
#' @param base_paths a character vector of paths to search the module in, in
#' order of preference.
#' @return \code{find_in_path} returns a \code{mod_info} that specifies the
#' module source location.
#' @details
#' A module is physically represented in the file system either by
#' \file{‹spec_name(spec)›.r} or by \file{‹spec_name(spec)›/__init__.r}, in that
#' order of preference in case both exist. File extensions are case insensitive
#' to allow for R’s obsession with capital-R extensions (but lower-case are
#' given preference, and upper-case file extensions are discouraged).
#' @keywords internal
find_in_path = function (spec, base_paths) {
    candidates = mod_file_candidates(spec, base_paths)
    hits = map(file.exists, candidates)
    which_base = which(map_lgl(any, hits))[1L]

    if (is.na(which_base)) {
        throw(
            'unable to load module {spec_name(spec);"}; ',
            'not found in {base_paths;"}'
        )
    }

    path = candidates[[which_base]][hits[[which_base]]][1L]
    base_path = base_paths[which_base]
    mod_info(spec, normalizePath(path))
}

mod_file_candidates = function (spec, base_paths) {
    mod_path_prefix = merge_path(spec$prefix)
    ext = c('.r', '.R')
    simple_mod = file.path(mod_path_prefix, paste0(spec$name, ext))
    nested_mod = file.path(mod_path_prefix, spec$name, paste0('__init__', ext))
    map(file.path, base_paths, list(c(simple_mod, nested_mod)))
}

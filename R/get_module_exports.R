#' List exports of a module or package
#'
#' \code{box::get_exports} supports reflection on {box} modules. This is the {box} version of
#' {base::getNamespaceExports}.
#'
#' @usage \special{box::get_exports(prefix/mod, \dots)}
#' @usage \special{box::get_exports(pkg, \dots)}
#' @usage \special{box::get_exports(alias = prefix/mod, \dots)}
#' @usage \special{box::get_exports(alias = pkg, \dots)}
#' @usage \special{box::get_exports(prefix/mod[attach_list], \dots)}
#' @usage \special{box::get_exports(pkg[attach_list], \dots)}
#'
#' @param prefix/mod a qualified module name
#' @param pkg a package name
#' @param alias an alias name
#' @param attach_list a list of names to attached, optionally witha aliases of
#' the form \code{alias = name}; or the special placeholder name \code{\dots}
#' @param \dots further import declarations
#' @return \code{box::get_module_exports} returns a list of attached packages, modules, and functions.
#'
#' @examples
#' # Set the module search path for the example module
#' old_opts = options(box.path = system.file(package = 'box'))
#'
#' # Basic usage
#' box::get_exports(mod/hello_world)
#'
#' # Using an alias
#' box::get_exports(world = mod/hello_world)
#'
#' # Attaching exported names
#' box::get_exports(mod/hello_world[hello])
#'
#' # Attach everything, give `hello` an alias:
#' box::get_exports(mod/hello_world[hi = hello, ...])
#'
#' # Reset the module search path
#' on.exit(options(old_opts))
#'
#' @seealso
#' \code{\link[=use]{box::use}} give information about importing modules or packages
#'
#' @export
get_exports = function (...) {
    caller = parent.frame()
    call = match.call()
    imports = call[-1L]
    aliases = names(imports) %||% character(length(imports))
    unlist(
        map(get_one, imports, aliases, list(caller), use_call = list(sys.call())),
        recursive = FALSE
    )
}

#' Get a module or package's exports without loading into the environment
#'
#' @param declaration an unevaluated use declaration expression without the
#' surrounding \code{use} call
#' @param alias the use alias, if given, otherwise \code{NULL}
#' @param caller the client’s calling environment (parent frame)
#' @param use_call the \code{use} call which is invoking this code
#' @return \code{get_one} return a list of functions exported.
#' @keywords internal
get_one = function (declaration, alias, caller, use_call) {
    if (declaration %==% quote(expr =) && alias %==% '') return()

    spec = parse_spec(declaration, alias)
    info = find_mod(spec, caller)
    mod_ns = load_mod(info)
    mod_exports = mod_exports(info, spec, mod_ns)

    exports = attach_list(spec, names(mod_exports))

    if (is.null(exports)) {
        exports = list(names(mod_exports))
        names(exports) = spec$alias
    }

    return(exports)
}

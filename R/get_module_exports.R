#' @export
get_module_exports = function (...) {
    caller = parent.frame()
    call = match.call()
    imports = call[-1L]
    aliases = names(imports) %||% character(length(imports))
    map(get_one, imports, aliases, list(caller), use_call = list(sys.call()))
}

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

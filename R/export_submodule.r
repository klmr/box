export_submodule = function (submodule) {
    parent = parent.frame()
    module = import(submodule)
    expose_single = function (symbol)
        assign(symbol, get(symbol, envir = module), envir = parent)
    invisible(lapply(ls(module), expose_single))
}

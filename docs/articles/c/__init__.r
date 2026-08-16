libname = function (name) {
    box::file(paste0(name, .Platform$dynlib.ext))
}

.on_load = function (ns) {
    ns$dll = dyn.load(libname('hello'))
}

.on_unload = function (ns) {
    dyn.unload(libname('hello'))
}

#' @export
hello_world = function (name) {
    .Call(dll$hello_world, name)
}

soname = function (name) {
    xyz::file(paste0(name, .Platform$dynlib.ext))
}

# xyz::on_install(function (...) xyz::use(./`__install__`))
# xyz::on_load(function (ns) assign('dll', dyn.load(soname('hello')), envir = ns))
dll = dyn.load(soname('hello'))

#' @export
hello_world = function (name) {
    .Call(dll$hello_world, name)
}

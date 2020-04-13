soname = function (name) {
    mod::file(paste0(name, .Platform$dynlib.ext))
}

# mod::on_install(function () mod::use(./`__install__`))
# mod::on_load(function () dyn.load(soname('hello')))
dll = dyn.load(soname('hello'))

#' @export
hello_world = function (name) {
    .Call(dll$hello_world, name)
}

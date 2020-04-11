#' @export
this_module_file = mod::file()

#' @export
function_module_file = function () mod::file()

mod::use(./a[...])

# Is this changed by the previous import/attach?
#' @export
this_module_file2 = mod::file()

#' @export
after_module_attach = function () {
    # Muffle message
    silently = function (expr) {
        on.exit({sink(); close(file)})
        file = textConnection('out', 'w', local = TRUE)
        sink(file)
        expr
    }
    silently(mod::use(a = ./nested/a[...]))
    on.exit(mod::unload(a))
    mod::file()
}

#' @export
after_package_attach = function () {
    mod::use(datasets[...])
    mod::file()
}

#' @export
nested_module_file = function () {
    local({
        mod::use(datasets[...])
        mod::file()
    })
}

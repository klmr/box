#' @export
this_module_file = xyz::file()

#' @export
function_module_file = function () xyz::file()

xyz::use(./a[...])

# Is this changed by the previous import/attach?
#' @export
this_module_file2 = xyz::file()

#' @export
after_module_attach = function () {
    # Muffle message
    silently = function (expr) {
        on.exit({sink(); close(file)})
        file = textConnection('out', 'w', local = TRUE)
        sink(file)
        expr
    }
    silently(xyz::use(a = ./nested/a[...]))
    on.exit(xyz::unload(a))
    xyz::file()
}

#' @export
after_package_attach = function () {
    xyz::use(datasets[...])
    xyz::file()
}

#' @export
nested_module_file = function () {
    local({
        xyz::use(datasets[...])
        xyz::file()
    })
}

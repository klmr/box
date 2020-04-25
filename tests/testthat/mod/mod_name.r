#' @export
this_module_name = xyz::name()

#' @export
function_module_name = function () xyz::name()

xyz::use(./a[...])

# Is this changed by the previous import/attach?
#' @export
this_module_name2 = xyz::name()

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
    xyz::name()
}

#' @export
after_package_attach = function () {
    xyz::use(datasets[...])
    xyz::name()
}

#' @export
nested_module_name = function () {
    local({
        xyz::use(datasets[...])
        xyz::name()
    })
}

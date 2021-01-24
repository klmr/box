#' @export
this_module_file = box::file()

#' @export
function_module_file = function () box::file()

box::use(./a[...])

# Is this changed by the previous import/attach?
#' @export
this_module_file2 = box::file()

#' @export
after_module_attach = function () {
    # Muffle message
    silently = function (expr) {
        on.exit({sink(); close(file)})
        file = textConnection('out', 'w', local = TRUE)
        sink(file)
        expr
    }
    silently(box::use(a = ./nested/a[...]))
    on.exit(box::unload(a))
    box::file()
}

#' @export
after_package_attach = function () {
    box::use(datasets[...])
    box::file()
}

#' @export
nested_module_file = function () {
    local({
        box::use(datasets[...])
        box::file()
    })
}

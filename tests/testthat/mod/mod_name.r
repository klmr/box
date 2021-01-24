#' @export
this_module_name = box::name()

#' @export
function_module_name = function () box::name()

box::use(./a[...])

# Is this changed by the previous import/attach?
#' @export
this_module_name2 = box::name()

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
    box::name()
}

#' @export
after_package_attach = function () {
    box::use(datasets[...])
    box::name()
}

#' @export
nested_module_name = function () {
    local({
        box::use(datasets[...])
        box::name()
    })
}

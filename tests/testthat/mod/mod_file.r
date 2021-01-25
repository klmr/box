#' @export
this_module_file = pod::file()

#' @export
function_module_file = function () pod::file()

pod::use(./a[...])

# Is this changed by the previous import/attach?
#' @export
this_module_file2 = pod::file()

#' @export
after_module_attach = function () {
    # Muffle message
    silently = function (expr) {
        on.exit({sink(); close(file)})
        file = textConnection('out', 'w', local = TRUE)
        sink(file)
        expr
    }
    silently(pod::use(a = ./nested/a[...]))
    on.exit(pod::unload(a))
    pod::file()
}

#' @export
after_package_attach = function () {
    pod::use(datasets[...])
    pod::file()
}

#' @export
nested_module_file = function () {
    local({
        pod::use(datasets[...])
        pod::file()
    })
}

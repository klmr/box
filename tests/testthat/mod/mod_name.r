#' @export
this_module_name = pod::name()

#' @export
function_module_name = function () pod::name()

pod::use(./a[...])

# Is this changed by the previous import/attach?
#' @export
this_module_name2 = pod::name()

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
    pod::name()
}

#' @export
after_package_attach = function () {
    pod::use(datasets[...])
    pod::name()
}

#' @export
nested_module_name = function () {
    local({
        pod::use(datasets[...])
        pod::name()
    })
}

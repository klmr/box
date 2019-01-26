#' @export
this_module_name = mod::name()

#' @export
function_module_name = function () mod::name()

mod::use(./a[...])

# Is this changed by the previous import/attach?
#' @export
this_module_name2 = mod::name()

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
    mod::name()
}

#' @export
after_package_attach = function () {
    mod::use(datasets[...])
    mod::name()
}

#' @export
nested_module_name = function () {
    local({
        mod::use(datasets[...])
        mod::name()
    })
}

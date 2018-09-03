this_module_name = mod::name()

function_module_name = function () mod::name()

import('a', attach = TRUE)

# Is this changed by the previous import/attach?
this_module_name2 = mod::name()

after_module_attach = function () {
    # Muffle message
    silently = function (expr) {
        on.exit({sink(); close(file)})
        file = textConnection('out', 'w', local = TRUE)
        sink(file)
        expr
    }
    a = silently(import('nested/a', attach = TRUE))
    on.exit(unload(a))
    mod::name()
}

after_package_attach = function () {
    import_package('datasets', attach = TRUE)
    mod::name()
}

nested_module_name = function () {
    local({
        import_package('datasets', attach = TRUE)
        mod::name()
    })
}

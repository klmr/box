this_module_file = module_file()

function_module_file = function () module_file()

import('a', attach = TRUE)

# Is this changed by the previous import/attach?
this_module_file2 = module_file()

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
    module_file()
}

after_package_attach = function () {
    import_package('datasets', attach = TRUE)
    module_file()
}

nested_module_file = function () {
    local({
        import_package('datasets', attach = TRUE)
        module_file()
    })
}

context('unloading')

is_module_loaded = function (path) {
    path %in% names(pod:::loaded_mods)
}

test_that('module can be unloaded', {
    pod::use(mod/a)
    path = pod:::path(a)
    expect_true(is_module_loaded(path))
    pod::unload(a)
    expect_false(is_module_loaded(path))
    expect_false(exists('a', inherits = FALSE))
})

test_that('unloaded module can be reloaded', {
    pod::use(mod/a)
    pod::unload(a)
    pod::use(mod/a)
    expect_true(is_module_loaded(pod:::path(a)))
    expect_true(exists('a', inherits = FALSE))
})

test_that('unload checks its arguments', {
    expect_error(pod::unload(123))
    expect_error(pod::unload(foo))
    pod::use(mod/a)
    expect_error(pod::unload((a)))
})

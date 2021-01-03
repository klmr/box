context('unloading')

is_module_loaded = function (path) {
    path %in% names(xyz:::loaded_mods)
}

test_that('module can be unloaded', {
    xyz::use(mod/a)
    path = xyz:::path(a)
    expect_true(is_module_loaded(path))
    xyz::unload(a)
    expect_false(is_module_loaded(path))
    expect_false(exists('a', inherits = FALSE))
})

test_that('unloaded module can be reloaded', {
    xyz::use(mod/a)
    xyz::unload(a)
    xyz::use(mod/a)
    expect_true(is_module_loaded(xyz:::path(a)))
    expect_true(exists('a', inherits = FALSE))
})

test_that('unload checks its arguments', {
    expect_error(xyz::unload(123))
    expect_error(xyz::unload(foo))
    xyz::use(mod/a)
    expect_error(xyz::unload((a)))
})

context('unloading')

is_module_loaded = function (path) {
    path %in% names(box:::loaded_mods)
}

test_that('module can be unloaded', {
    box::use(mod/a)
    path = box:::path(a)
    expect_true(is_module_loaded(path))
    box::unload(a)
    expect_false(is_module_loaded(path))
    expect_false(exists('a', inherits = FALSE))
})

test_that('unloaded module can be reloaded', {
    box::use(mod/a)
    box::unload(a)
    box::use(mod/a)
    expect_true(is_module_loaded(box:::path(a)))
    expect_true(exists('a', inherits = FALSE))
})

test_that('unload checks its arguments', {
    expect_error(box::unload(123))
    expect_error(box::unload(foo))
    box::use(mod/a)
    expect_error(box::unload((a)))
})

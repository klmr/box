context('Module unloading')

is_module_loaded = function (path) {
    path %in% names(mod:::loaded_mods)
}

test_that('module can be unloaded', {
    mod::use(mod/a)
    path = mod::path(a)
    expect_true(is_module_loaded(path))
    mod::unload(a)
    expect_false(is_module_loaded(path))
    expect_false(exists('a', inherits = FALSE))
})

test_that('unloaded module can be reloaded', {
    mod::use(mod/a)
    mod::unload(a)
    mod::use(mod/a)
    expect_true(is_module_loaded(mod::path(a)))
    expect_true(exists('a', inherits = FALSE))
})

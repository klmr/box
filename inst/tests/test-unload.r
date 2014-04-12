context('Module unloading')

test_that('module can be unloaded', {
    a = import('a')
    path = module_path(a)
    expect_true(is_module_loaded(path))
    unload(a)
    expect_false(is_module_loaded(path))
    expect_false(exists('a', inherits = FALSE))
})

test_that('unloaded module can be reloaded', {
    a = import('a')
    unload(a)
    a = import('a')
    expect_true(is_module_loaded(module_path(a)))
    expect_true(exists('a', inherits = FALSE))
})

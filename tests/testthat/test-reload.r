context('Module reloading')

unload_all = function () {
    modenv = mod:::loaded_mods
    rm(list = ls(modenv), envir = modenv)
}

test_that('module can be reloaded', {
    # Required since other tests have side-effects.
    # Tear-down would be helpful here, but not supported by testthat.
    unload_all()

    mod::use(mod/a)
    expect_equal(length(mod:::loaded_mods), 1)
    counter = a$get_counter()
    a$inc()
    expect_equal(a$get_counter(), counter + 1)

    mod::reload(a)
    expect_true(is_module_loaded(module_path(a)))
    expect_equal(length(mod:::loaded_modules), 1)
    expect_equal(a$get_counter(), counter)
})

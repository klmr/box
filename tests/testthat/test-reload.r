context('Module reloading')

is_module_loaded = function (path) {
    path %in% names(xyz:::loaded_mods)
}

unload_all = function () {
    modenv = xyz:::loaded_mods
    rm(list = ls(modenv), envir = modenv)
}

test_that('module can be reloaded', {
    # Required since other tests have side-effects.
    # Tear-down would be helpful here, but not supported by testthat.
    unload_all()

    xyz::use(mod/a)
    expect_equal(length(xyz:::loaded_mods), 1)
    counter = a$get_counter()
    a$inc()
    expect_equal(a$get_counter(), counter + 1)

    xyz::reload(a)
    expect_true(is_module_loaded(xyz::path(a)))
    expect_equal(length(xyz:::loaded_mods), 1)
    expect_equal(a$get_counter(), counter)
})

test_that('reload checks its arguments', {
    expect_error(xyz::reload(123))
    expect_error(xyz::reload(foo))
    xyz::use(mod/a)
    expect_error(xyz::reload((a)))
})

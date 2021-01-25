context('reloading')

is_module_loaded = function (path) {
    path %in% names(pod:::loaded_mods)
}

unload_all = function () {
    modenv = pod:::loaded_mods
    rm(list = ls(modenv), envir = modenv)
}

test_that('module can be reloaded', {
    # Required since other tests have side-effects.
    # Tear-down would be helpful here, but not supported by testthat.
    unload_all()

    pod::use(mod/a)
    expect_equal(length(pod:::loaded_mods), 1L)
    counter = a$get_counter()
    a$inc()
    expect_equal(a$get_counter(), counter + 1L)

    pod::reload(a)
    expect_true(is_module_loaded(pod:::path(a)))
    expect_equal(length(pod:::loaded_mods), 1L)
    expect_equal(a$get_counter(), counter)
})

test_that('reload checks its arguments', {
    expect_error(pod::reload(123))
    expect_error(pod::reload(foo))
    pod::use(mod/a)
    expect_error(pod::reload((a)))
})

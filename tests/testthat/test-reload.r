context('reloading')

is_module_loaded = function (path) {
    path %in% names(box:::loaded_mods)
}

unload_all = function () {
    modenv = box:::loaded_mods
    rm(list = ls(modenv), envir = modenv)
}

test_that('module can be reloaded', {
    # Required since other tests have side-effects.
    # Tear-down would be helpful here, but not supported by testthat.
    unload_all()

    box::use(mod/a)
    expect_equal(length(box:::loaded_mods), 1L)
    counter = a$get_counter()
    a$inc()
    expect_equal(a$get_counter(), counter + 1L)

    box::reload(a)
    expect_true(is_module_loaded(box:::path(a)))
    expect_equal(length(box:::loaded_mods), 1L)
    expect_equal(a$get_counter(), counter)
})

test_that('reload checks its arguments', {
    expect_error(box::reload(123))
    expect_error(box::reload(foo))
    box::use(mod/a)
    expect_error(box::reload((a)))
})

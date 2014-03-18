context('Module reloading')

unload_all = function () {
    modenv = import:::.loaded_modules
    rm(list = ls(modenv), envir = modenv)
}

test_that('module can be reloaded', {
    # Required since other tests have side-effects.
    # Tear-down would be helpful here, but not supported by testthat.
    unload_all()

    a = import(a)
    expect_that(length(import:::.loaded_modules), equals(1))
    counter = a$counter
    a$inc()
    expect_that(a$counter, equals(counter + 1))

    reload(a)
    expect_true(is_module_loaded(module_path(a)))
    expect_that(length(import:::.loaded_modules), equals(1))
    expect_that(a$counter, equals(counter))
})

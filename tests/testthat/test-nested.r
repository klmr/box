context('submodules')

teardown = function () {
    # Unload all modules
    rm(list = ls(envir = mod:::loaded_mods), envir = mod:::loaded_mods)
}

test_that('submodules can be loaded one by one', {
    on.exit(teardown())

    result = capture.output(mod::use(mod/nested/a/b))
    expect_that(result, equals(c('a/__init__.r', 'a/b/__init__.r')))

    result = capture.output(mod::use(mod/nested/a/b/c))
    expect_that(result, equals('a/b/c/__init__.r'))

    result = capture.output(mod::use(mod/nested/a/b/d))
    expect_that(result, equals('a/b/d/__init__.r'))

    result = capture.output(mod::use(mod/nested/a/b/c/e))
    expect_that(result, equals('a/b/c/e.r'))
})

test_that('module can export nested submodules', {
    b = mod::use(mod/b)
    expect_equal(b$answer, 42L)
})

test_that('submodules load all relevant init files', {
    on.exit(teardown())

    result = capture.output(mod::use(mod/nested/a/b/d))
    expect_that(result, equals(c('a/__init__.r', 'a/b/__init__.r', 'a/b/d/__init__.r')))

    result = capture.output(mod::use(mod/nested/a/b/c/e))
    expect_that(result, equals(c('a/b/c/__init__.r', 'a/b/c/e.r')))
})

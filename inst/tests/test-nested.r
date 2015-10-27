context('Submodules test')

setup = function () {
    thispath = 'modules/nested'
    prev = getOption('import.path')
    if (! identical(prev, thispath))
        previous_import_path <<- prev
    options(import.path = thispath)
}

teardown = function () {
    options(import.path = previous_import_path)
    # Unload all modules
    rm(list = ls(envir = modules:::loaded_modules),
       envir = modules:::loaded_modules)
}

test_that('submodules can be loaded one by one', {
    setup()
    on.exit(teardown())

    result = capture.output(import('a/b'))
    expect_that(result, equals(c('a/__init__.r', 'a/b/__init__.r')))

    result = capture.output(import('a/b/c'))
    expect_that(result, equals('a/b/c/__init__.r'))

    result = capture.output(import('a/b/d'))
    expect_that(result, equals('a/b/d/__init__.r'))

    result = capture.output(import('a/b/c/e'))
    expect_that(result, equals('a/b/c/e.r'))
})

test_that('module can export nested submodules', {
    b = import('b')
    expect_that(b$answer, equals(42))
})

test_that('submodules load all relevant init files', {
    setup()
    on.exit(teardown())

    result = capture.output(import('a/b/d'))
    expect_that(result, equals(c('a/__init__.r', 'a/b/__init__.r', 'a/b/d/__init__.r')))

    result = capture.output(import('a/b/c/e'))
    expect_that(result, equals(c('a/b/c/__init__.r', 'a/b/c/e.r')))
})

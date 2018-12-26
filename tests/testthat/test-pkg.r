context('packages')

test_that('R core packages can be used', {
    expect_not_in('methods', ls())
    mod::use(methods)
    expect_true(isNamespaceLoaded('methods'))
    expect_in('methods', ls())
    expect_in('as', ls(methods))
    expect_identical(methods$as, methods::as)
})

# Use {devtools} as a test package since it’s suggested by testthat and required
# for {mod} development, so highly likely to be installed, but hopefully not
# loaded.

test_that('previously loaded user packages can be used', {
    loadNamespace('devtools')
    expect_not_in('devtools', ls())
    expect_true(isNamespaceLoaded('devtools'))
    mod::use(devtools)
    expect_in('devtools', ls())
    expect_in('load_all', ls(devtools))
    expect_identical(devtools$load_all, devtools::load_all)
})

test_that('unloaded user packages can be used', {
    unloadNamespace('devtools')
    expect_not_in('devtools', ls())
    expect_false(isNamespaceLoaded('devtools'))
    mod::use(devtools)
    expect_true(isNamespaceLoaded('devtools'))
    expect_in('devtools', ls())
    expect_in('load_all', ls(devtools))
    expect_identical(devtools$load_all, devtools::load_all)
})

test_that('packages can be aliased', {
    expect_not_in('methods', ls())
    expect_not_in('m', ls())
    mod::use(m = methods)
    expect_not_in('methods', ls())
    expect_in('m', ls())
    expect_in('as', ls(m))
    expect_identical(m$as, methods::as)
})

test_that('packages can be used with aliases', {
    expect_not_in('dev', ls())
    mod::use(dev = devtools)
    expect_in('dev', ls())
    expect_identical(dev$load_all, devtools::load_all)
})

test_that('things can be attached locally', {
    expect_not_in('load_all', ls())
    mod::use(devtools[load_all])
    expect_in('load_all', ls())

    expect_not_in('unload', ls())
    expect_not_in('reload', ls())
    mod::use(devtools[unload, reload])
    expect_in('unload', ls())
    expect_in('reload', ls())
})

test_that('all things can be attached locally', {
    # Mark this name invisible to make the comparison simpler
    .devtools_exports = getNamespaceExports('devtools')
    expect_gt(length(.devtools_exports), 0L) # Sanity check …
    mod::use(devtools[...])
    expect_false(any(is.na(match(ls(), .devtools_exports))))
})

test_that('things can be attached globally', {
    in_globalenv({
        expect_not_in('load_all', ls())
        mod::use(devtools[load_all])
        expect_in('load_all', ls())

        expect_not_in('unload', ls())
        expect_not_in('reload', ls())
        mod::use(devtools[unload, reload])
        expect_in('unload', ls())
        expect_in('reload', ls())
    })
})

test_that('all things can be attached globally', {
    in_globalenv({
        .devtools_exports = getNamespaceExports('devtools')
        expect_gt(length(.devtools_exports), 0L) # Sanity check …
        mod::use(devtools[...])
        expect_false(any(is.na(match(ls(), .devtools_exports))))
    })
})

test_that('attachments can be aliased', {
    expect_not_in('u', ls())
    expect_not_in('reload', ls())
    expect_not_in('la', ls())
    mod::use(devtools[u = unload, reload, la = load_all])
    expect_in('u', ls())
    expect_in('reload', ls())
    expect_in('la', ls())
    expect_not_in('unload', ls())
    expect_not_in('load_all', ls())
})

test_that('wildcard attachments can contain aliases', {
    # Attach everything, and give some names aliases
    devtools_exports = getNamespaceExports('devtools')
    expected = c(
        setdiff(devtools_exports, c('test', 'r_env_vars')),
        'test_alias', 'ev',
        'devtools_exports', 'expected'
    )
    expect_length(ls(), 2L) # = `devtools_exports`, `expected`
    mod::use(devtools[..., test_alias = test, ev = r_env_vars])
    expect_equal(length(ls()), length(expected))
    expect_false(any(is.na(match(ls(), expected))))
})

test_that('non-existent aliases raise error', {
    expect_error(mod::use(devtools[foobar123]))
    expect_error(mod::use(devtools[test = foobar123]))
    expect_error(mod::use(devtools[..., test = foobar123]))
})

test_that('only exported things can be attached', {
    expect_in('indent', ls(getNamespace('devtools')))
    expect_error(mod::use(devtools[indent]), 'not exported')
})

test_that('packages that attach things are not aliased', {
    mod::use(devtools[load_all])
    expect_not_in('devtools', ls())
    expect_in('load_all', ls())
})

test_that('packages that attach things are can be aliased', {
    expect_not_in('dev', ls())
    mod::use(dev = devtools[load_all])
    expect_in('load_all', ls())
    expect_in('dev', ls())
})

test_that('S3 lookup works for partial exports', {
    # {devtools} has no S3 exports at the time of writing but {roxygen2} does,
    # and is also needed to compile this package — and hence likely available
    # when running these tests.
    mod::use(roxygen2[tags = roclet_tags, roclet])
    actual = tags(roclet('rd'))
    expected = roxygen2::roclet_tags(roxygen2::roclet('rd'))
    expect_gt(length(actual), 0L)
    expect_equal(actual, expected)
})

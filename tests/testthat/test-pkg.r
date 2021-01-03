context('packages')

# Helper function to check for existence of an attached name (which is expected
# to be found in the parent environment of the calling environment).
local({
    pls = function () {
        ls(envir = parent.env(parent.frame()))
    }
}, .GlobalEnv)

test_that('R core packages can be used', {
    expect_not_in('methods', ls())
    xyz::use(methods)
    expect_true(isNamespaceLoaded('methods'))
    expect_in('methods', ls())
    expect_in('as', ls(methods))
    expect_identical(methods$as, methods::as)
})

# Use ‘devtools’ as a test package since it’s suggested by testthat and required
# for ‘xyz’/ development, so highly likely to be installed, but hopefully not
# loaded.

test_that('previously loaded user packages can be used', {
    loadNamespace('devtools')
    expect_not_in('devtools', ls())
    expect_true(isNamespaceLoaded('devtools'))
    xyz::use(devtools)
    expect_in('devtools', ls())
    expect_in('load_all', ls(devtools))
    expect_identical(devtools$load_all, devtools::load_all)
})

test_that('unloaded user packages can be used', {
    unloadNamespace('devtools')
    expect_not_in('devtools', ls())
    expect_false(isNamespaceLoaded('devtools'))
    xyz::use(devtools)
    expect_true(isNamespaceLoaded('devtools'))
    expect_in('devtools', ls())
    expect_in('load_all', ls(devtools))
    expect_identical(devtools$load_all, devtools::load_all)
})

test_that('packages can be aliased', {
    expect_not_in('methods', ls())
    expect_not_in('m', ls())
    xyz::use(m = methods)
    expect_not_in('methods', ls())
    expect_in('m', ls())
    expect_in('as', ls(m))
    expect_identical(m$as, methods::as)
})

test_that('packages can be used with aliases', {
    expect_not_in('dev', ls())
    xyz::use(dev = devtools)
    expect_in('dev', ls())
    expect_identical(dev$load_all, devtools::load_all)
})

test_that('things can be attached locally', {
    expect_not_in('load_all', pls())
    xyz::use(devtools[load_all])
    expect_in('load_all', pls())

    expect_not_in('unload', pls())
    expect_not_in('reload', pls())
    xyz::use(devtools[unload, reload])
    expect_in('unload', pls())
    expect_in('reload', pls())
})

test_that('all things can be attached locally', {
    devtools_exports = getNamespaceExports('devtools')
    expect_gt(length(devtools_exports), 0L) # Sanity check …
    xyz::use(devtools[...])
    expect_false(any(is.na(match(pls(), devtools_exports))))
})

test_that('things can be attached globally', {
    in_globalenv({
        xyz:::expect_not_in('load_all', pls())
        xyz::use(devtools[load_all])
        xyz:::expect_in('load_all', pls())

        xyz:::expect_not_in('unload', pls())
        xyz:::expect_not_in('reload', pls())
        xyz::use(devtools[unload, reload])
        xyz:::expect_in('unload', pls())
        xyz:::expect_in('reload', pls())
    })
})

test_that('all things can be attached globally', {
    in_globalenv({
        devtools_exports = getNamespaceExports('devtools')
        expect_gt(length(devtools_exports), 0L) # Sanity check …
        xyz::use(devtools[...])
        expect_false(any(is.na(match(pls(), devtools_exports))))
    })
})

test_that('attachments can be aliased', {
    expect_not_in('u', pls())
    expect_not_in('reload', pls())
    expect_not_in('la', pls())
    xyz::use(devtools[u = unload, reload, la = load_all])
    expect_in('u', pls())
    expect_in('reload', pls())
    expect_in('la', pls())
    expect_not_in('unload', pls())
    expect_not_in('load_all', pls())
})

test_that('wildcard attachments can contain aliases', {
    # Attach everything, and give some names aliases
    devtools_exports = getNamespaceExports('devtools')
    expected = c(
        setdiff(devtools_exports, c('test', 'r_env_vars')),
        'test_alias', 'ev'
    )
    xyz::use(devtools[..., test_alias = test, ev = r_env_vars])
    expect_equal(length(pls()), length(expected))
    expect_false(any(is.na(match(pls(), expected))))
})

test_that('non-existent aliases raise error', {
    expect_error(xyz::use(devtools[foobar123]))
    expect_error(xyz::use(devtools[test = foobar123]))
    expect_error(xyz::use(devtools[..., test = foobar123]))
})

test_that('only exported things can be attached', {
    expect_in('indent', ls(getNamespace('devtools')))
    expect_error(xyz::use(devtools[indent]), 'not exported')
})

test_that('packages that attach things are not aliased', {
    xyz::use(devtools[load_all])
    expect_not_in('devtools', ls())
    expect_in('load_all', pls())
})

test_that('packages that attach things are can be aliased', {
    expect_not_in('dev', ls())
    xyz::use(dev = devtools[load_all])
    expect_in('dev', ls())
    expect_in('load_all', pls())
})

test_that('S3 lookup works for partial exports', {
    # ‘devtools’ has no S3 exports at the time of writing but ‘roxygen2’ does,
    # and is also needed to compile this package — and hence likely available
    # when running these tests.
    xyz::use(roxygen2[parse = roxy_tag_parse])
    x = structure(list(raw = '{}'), class = 'roxy_tag_usage')
    actual = parse(x)
    expected = roxygen2::roxy_tag_parse(x)
    expect_equal(actual, expected)
})

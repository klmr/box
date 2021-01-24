context('operators')

test_that('S3 operators work', {
    box::use(a = mod/a[...])
    on.exit(box::unload(a))

    expect_equal(1L + 2L, 3L)
    s = structure('foo', class = 'string')
    expect_equal(s + 'bar', 'foobar')
})

test_that('dot operators work', {
    # Test cases for the fix of issue 42.
    expect_false(exists('%.%'))
    expect_false(exists('%x.%'))
    expect_false(exists('%.x%'))
    expect_false(exists('%x.x%'))
    # S3 generic `%%`
    expect_false(exists('%%.%%'))
    expect_false(exists('%a%.class%'))

    box::use(a = mod/a[...])
    on.exit(unload(a))

    expect_true(exists('%.%'))
    expect_true(exists('%x.%'))
    expect_true(exists('%.x%'))
    expect_true(exists('%x.x%'))
    expect_true(exists('%%.%%'))
    expect_true(exists('%a%.class%'))
    # S3 method (not an operator)
    expect_true(exists('%foo.bar', envir = a))
})

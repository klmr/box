context('Operator export test')

test_that('operators are attached by default', {
    expect_false(exists('%or%'))
    a = import('a')
    on.exit(unload(a))

    expect_true(exists('%or%'))
    expect_that(1 %or% 2, equals(1))
    expect_that(numeric(0) %or% 2, equals(2))
})

test_that('operator attachment can be disabled', {
    expect_false(exists('%or%'))
    a = import('a', attach_operators = FALSE)
    on.exit(unload(a))

    expect_false(exists('%or%'))
})

test_that('it works in the global environment', {
    local({
        expect_false(exists('%or%'))
        a = import('a')
        on.exit(unload(a))
        expect_true(exists('%or%'))
    }, envir = .GlobalEnv)
})

test_that('S3 operators work', {
    a = import('a')
    on.exit(unload(a))

    expect_that(1 + 2, equals(3))
    s = structure('foo', class = 'string')
    expect_that(s + 'bar', equals('foobar'))
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

    a = import('a')
    on.exit(unload(a))

    expect_true(exists('%.%'))
    expect_true(exists('%x.%'))
    expect_true(exists('%.x%'))
    expect_true(exists('%x.x%'))
    expect_true(exists('%%.%%'))
    expect_true(exists('%a%.class%'))
    # S3 method (not an operator)
    expect_true(exists('%foo.bar', envir = a))
    expect_false(exists('%foo.bar'))
})

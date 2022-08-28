context('S3')

test_that('S3 generics are recognized', {
    foo = function (x) UseMethod('foo')
    bar = function (x) print('UseMethod')
    baz = function (x) {
        x = 42
        UseMethod('baz')
    }
    qux = function (x) {
        UseMethod('print')
        a = 12
    }
    quz = function (x)
        foo(bar(sum(1, UseMethod('quz'))))

    expect_true(is_S3_user_generic('foo'))
    expect_false(is_S3_user_generic('bar'))
    expect_true(
        is_S3_user_generic('baz'),
        'Multi-statement method not recognized'
    )
    expect_true(
        is_S3_user_generic('qux'),
        'Method cannot dispatch to generic of different name'
    )
    expect_true(
        is_S3_user_generic('quz'),
        '`UseMethod` can be nested in other calls'
    )
})

test_that('S3 methods are found', {
    box::use(mod/s3)
    s3ns = environment(s3$test)
    test = getS3method('test', 'character', envir = s3)
    test_dot_character = s3ns$test.character
    expect_identical(test, test_dot_character)

    # NOT executed locally!
    print = getS3method('print', 'test')
    print_dot_test = s3ns$print.test
    expect_identical(print, print_dot_test)
})

test_that('can call S3 methods without attaching', {
    box::use(mod/s3)
    expect_equal(s3$test(1), 'test.default')
    expect_equal(s3$test('a'), 'test.character')

    foo = structure(42, class = 'test')
    expect_equal(print(foo), 's3$print.test')
})

test_that('S3 methods are not registered twice', {
    box::use(mod/s3)

    result = s3$se(structure(1, class = 'contrast.test'))
    expect_equal(
        result, 's3$se.default',
        'Generic does not call `se.contrast.test`'
    )

    result = se.contrast(structure(1, class = 'test'))
    expect_equal(
        result, 's3$se.contrast.test',
        'Known generics are still callable'
    )
})

test_that('Forwarded S3 genetics without methods work', {
    box::use(mod/s3_b)
    expect_equal(s3_b$test(1), 'test.default')
    expect_equal(s3_b$test('a'), 'test.character')
})

test_that('`is_S3_user_generic` can deal with substituted functions', {
    expect_error(box::use(mod/issue125), NA)
})

test_that('nested functions are parsed correctly', {
    expect_error(box::use(mod/issue203), NA)
    expect_false(box:::is_S3_user_generic('g', issue203))
    expect_false(box:::is_S3_user_generic('h', issue203))
})

test_that('functions with missing arguments are parsed correctly', {
    expect_error(is_S3(quote(tag$span('foo', ))), NA)
    expect_error(is_S3(quote(base$quote(expr =))), NA)
    expect_error(is_S3(quote((quote)(expr =))), NA)
})

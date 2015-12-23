context('S3 dispatch test')

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
    expect_true(is_S3_user_generic('baz'),
                'Multi-statement method not recognized')
    expect_true(is_S3_user_generic('qux'),
                'Method cannot dispatch to generic of different name')
    expect_true(is_S3_user_generic('quz'),
                '`UseMethod` can be nested in other calls')
})

test_that('S3 methods are found', {
    s3 = import('s3')
    test = local(getS3method('test', 'character'), s3)
    expect_that(test, equals(s3$test.character))

    # NOT executed locally!
    print = getS3method('print', 'test')
    expect_that(print, equals(s3$print.test))
})


test_that('can call S3 methods without attaching', {
    s3 = import('s3')
    expect_that(s3$test(1), equals('test.default'))
    expect_that(s3$test('a'), equals('test.character'))

    foo = structure(42, class = 'test')
    expect_that(print(foo), equals('s3$print.test'))
})

test_that('S3 methods are not registered twice', {
    s3 = import('s3')

    result = s3$se(structure(1, class = 'contrast.test'))
    expect_that(result, equals('s3$se.default'),
                'Generic does not call `se.contrast.test`')

    result = se.contrast(structure(1, class = 'test'))
    expect_that(result, equals('s3$se.contrast.test'),
                'Known generics are still callable')
})

test_that('Forwarded S3 genetics without methods work', {
    s3_b = import('s3_b')
    expect_that(s3_b$test(1), equals('test.default'))
    expect_that(s3_b$test('a'), equals('test.character'))
})

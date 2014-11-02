context('S3 dispatch test')

test_that('S3 methods are found', {
    s3 = import('s3')
    test = local(getS3method('test', 'character', s3))
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

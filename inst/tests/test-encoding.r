context('Source file encoding')

test_that('source is read as UTF-8', {
    a = import('a')
    expected_bytes = as.raw(c(0xE2, 0x98, 0x83))
    expect_that(nchar(a$encoding_test(), 'bytes'), equals(3))
    expect_that(Encoding(a$encoding_test()), equals('UTF-8'))
    expect_that(charToRaw(a$encoding_test()), equals(expected_bytes))
})

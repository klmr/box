context('encoding')

test_that('source is read as UTF-8', {
    box::use(mod/a)
    expected_bytes = as.raw(c(0xE2, 0x98, 0x83))
    expect_equal(nchar(a$encoding_test(), 'bytes'), 3L)
    expect_equal(Encoding(a$encoding_test()), 'UTF-8')
    expect_equal(charToRaw(a$encoding_test()), expected_bytes)
})

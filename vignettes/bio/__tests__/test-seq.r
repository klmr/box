test_that('valid sequences can be created', {
    expect_error((s = seq('GATTACA')), NA)
    expect_true(is_valid(s))

    expect_error(seq('cattaga'), NA)
})

test_that('invalid sequences cannot be created', {
    expect_error(seq('GATTXA'))
})

test_that('nucleotide frequencies are correct', {
    s = seq('GATTACA')
    expected = as.table(c(A = 3L, C = 1L, G = 1L, T = 2L))
    expect_equal(table(s)[[1L]], expected)
})

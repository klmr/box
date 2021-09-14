context('meta')

# Test that the custom expectations behave as expected

test_that('`expect_not_equal` works', {
    expect_not_equal(1, 2)
    expect_not_equal('a', 'A')
    expect_failure(expect_not_equal(1, 1))

})

test_that('`expect_not_identical` works', {
    expect_not_identical(1, 2)
    expect_not_identical(1, 1L)
    expect_not_identical(new.env(), new.env())

    expect_failure(expect_not_identical(1, 1))
    expect_failure(expect_not_identical(list('a'), list('a')))
    expect_failure(expect_not_identical(asNamespace('base'), .BaseNamespaceEnv))
})

test_that('`expect_in` works', {
    expect_in(1, c(1, 2, 3))
    expect_in(2, c(1, 2, 3))
    expect_in('A', LETTERS)

    expect_failure(expect_in(1, c()))
    expect_failure(expect_in(1, c(2, 3)))
    expect_failure(expect_in('A', letters))
})

test_that('`expect_not_in` works', {
    expect_not_in(1, c())
    expect_not_in(1, c(2, 3))
    expect_not_in('A', letters)

    expect_failure(expect_not_in(1, c(1, 2, 3)))
    expect_failure(expect_not_in(2, c(1, 2, 3)))
    expect_failure(expect_not_in('A', LETTERS))
})

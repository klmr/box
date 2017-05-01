context('Circular dependencies between modules')

test_that('circular dependencies load in finite time', {
    a = import('circular_a')
    expect_true(TRUE)
})

test_that('circular import order is predictable', {
    a = import('circular_a')
    b = import('circular_b')

    expect_that(a$getx(), equals(2))
    expect_that(b$getx(), equals(1))
})

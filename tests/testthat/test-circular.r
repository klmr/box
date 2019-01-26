context('Circular dependencies between modules')

test_that('circular dependencies load in finite time', {
    mod::use(mod/circular_a)
    expect_true(TRUE)
})

test_that('circular import order is predictable', {
    mod::use(a = mod/circular_a)
    mod::use(b = mod/circular_b)

    expect_that(a$getx(), equals(2))
    expect_that(b$getx(), equals(1))
})

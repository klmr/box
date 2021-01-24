context('circular dependencies')

test_that('cyclic dependencies load in finite time', {
    box::use(mod/cyclic_a)
    expect_true(TRUE)
})

test_that('cyclic import fully loads dependencies', {
    box::use(a = mod/cyclic_a)
    box::use(b = mod/cyclic_b)

    expect_equal(a$name, 'a')
    expect_equal(b$name, 'b')
    expect_equal(a$b_name(), 'b')
    expect_equal(b$a_name(), 'a')
    expect_equal(a$b$name, 'b')
    expect_equal(b$a$name, 'a')
    expect_equal(a$b$a$b_name(), 'b')
    expect_equal(a$b$a$name, 'a')
    expect_equal(b$a$b$a_name(), 'a')
    expect_equal(b$a$b$name, 'b')
})

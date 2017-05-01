context('Relative imports test')

test_that('Imports are absolute by default', {
    ra = import('./modules/nested/relative_a')
    expect_that(ra$a_which(), equals('/a'))
})

test_that('Relative import are always local', {
    ra = import('./modules/nested/relative_a')
    expect_that(ra$local_a_which(), equals('nested/a'))
})

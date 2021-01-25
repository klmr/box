context('relative imports')

test_that('Imports are absolute by default', {
    old_opts = options(pod.path = getwd())
    on.exit(options(old_opts))

    pod::use(mod/nested/relative_a)
    expect_equal(relative_a$a_which(), '/a')
})

test_that('Relative import are always local', {
    old_opts = options(pod.path = getwd())
    on.exit(options(old_opts))

    pod::use(mod/nested/relative_a)
    expect_equal(relative_a$local_a_which(), 'nested/a')
})

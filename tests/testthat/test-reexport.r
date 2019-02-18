context('reexport')

test_that('module reexport exposes the correct names', {
    mod::use(x = mod/reexport)

    expect_true('a' %in% ls(x))
    expect_true('b' %in% ls(x))
    expect_true('c' %in% ls(x))
    expect_true('sub' %in% ls(x))
    expect_false('d' %in% ls(x))

    expect_equal(x$a, 'sub$c')
    expect_equal(x$b, 'sub$b')
    expect_equal(x$c, 'reexport$c')
})

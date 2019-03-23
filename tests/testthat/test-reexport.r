context('reexport')

test_that('module reexport exposes the correct names', {
    mod::use(x = mod/reexport)

    xns = attr(x, 'namespace')
    exports = mod::namespace_info(xns, 'exports')
    expect_equal(sort(exports), c('a', 'b', 'c', 'sub'))
})

test_that('module reexports the correct names', {
    mod::use(x = mod/reexport)

    expect_true('a' %in% ls(x))
    expect_true('b' %in% ls(x))
    expect_true('c' %in% ls(x))
    expect_true('sub' %in% ls(x))
    expect_false('d' %in% ls(x))
})

test_that('module reexport names refer to correct objects', {
    mod::use(x = mod/reexport)

    expect_equal(x$a, 'sub$c')
    expect_equal(x$b, 'sub$b')
    expect_equal(x$c, 'reexport$c')
})

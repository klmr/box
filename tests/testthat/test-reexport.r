context('reexport')

test_that('module reexport exposes the correct names', {
    pod::use(x = mod/reexport)

    xns = attr(x, 'namespace')
    exports = pod:::namespace_info(xns, 'exports')
    direct_exports = c('a', 'c')
    sub_exports = c('d', 'e')
    all_expected_exports = c(direct_exports, sub_exports, 'sub')
    expect_equal(sort(exports), sort(all_expected_exports))
})

test_that('module reexports the correct names', {
    pod::use(x = mod/reexport)

    exported_names = c('a', 'c', 'sub', 'd', 'e')
    expect_true('a' %in% ls(x))
    expect_false('b' %in% ls(x))
    expect_true('c' %in% ls(x))
    expect_true('sub' %in% ls(x))
    expect_true('d' %in% ls(x))
})

test_that('module reexport names refer to correct objects', {
    pod::use(x = mod/reexport)

    expect_equal(x$sub$a, 'sub$a')
    expect_equal(x$sub$b, 'sub$b')
    expect_equal(x$c, 'reexport$c')
    expect_equal(x$d, 'sub$c')
    expect_equal(x$e, 'sub$b')
})

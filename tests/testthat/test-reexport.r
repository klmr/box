context('reexport')

test_that('module reexport exposes the correct names', {
    box::use(x = mod/reexport)

    xns = attr(x, 'namespace')
    exports = box:::namespace_info(xns, 'exports')
    direct_exports = c('a', 'c')
    sub_exports = c('d', 'e')
    all_expected_exports = c(direct_exports, sub_exports, 'sub')
    expect_setequal(exports, all_expected_exports)
})

test_that('module reexports the correct names', {
    box::use(x = mod/reexport)

    exported_names = c('a', 'c', 'sub', 'd', 'e')
    expect_in('a', ls(x))
    expect_not_in('b', ls(x))
    expect_in('c', ls(x))
    expect_in('sub', ls(x))
    expect_in('d', ls(x))
})

test_that('module reexport names refer to correct objects', {
    box::use(x = mod/reexport)

    expect_equal(x$sub$a, 'sub$a')
    expect_equal(x$sub$b, 'sub$b')
    expect_equal(x$c, 'reexport$c')
    expect_equal(x$d, 'sub$c')
    expect_equal(x$e, 'sub$b')
})

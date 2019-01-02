context('find_mod')

test_use = function (...) {
    call = match.call()
    parse_spec(call[[2L]], names(call[-1L]))
}

test_that('"./" can only be used as a prefix', {
    expect_error(test_use(./a), NA)
    expect_error(test_use(.././a))
    expect_error(test_use(a/./b))
    expect_error(test_use(a/.))
    expect_error(test_use(a/b/./c))
})

test_that('"../" can only be used as a prefix', {
    expect_error(test_use(../a), NA)
    expect_error(test_use(../../a), NA)
    expect_error(test_use(./../a))
    expect_error(test_use(a/../b))
    expect_error(test_use(../a/../b))
    expect_error(test_use(a/..))
    expect_error(test_use(a/b/../c))
})

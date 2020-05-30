context('partial attaching')

test_that('partial attach works locally', {
    a = xyz::use(mod/a[double])
    expect_equal(ls(parent.env(environment())), 'double')
})

test_that('partial attach works globally', {
    exports = c('inc', 'get_counter')
    local(xyz::use(a = mod/a[inc, get_counter]), envir = .GlobalEnv)
    expect_equal(search()[2L], environmentName(a))
    on.exit(detach(), add = TRUE)
    expect_equal(sort(ls(2L)), c('get_counter', 'inc'))
})

test_that('Invalid attach specifier raises error', {
    expect_error(
        xyz::use(mod/a[foo, bar]),
        regexp = 'Names .* not exported by'
    )
})

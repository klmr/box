context('partial attaching')

test_that('partial attach works locally', {
    a = mod::use(mod/a[double])
    expect_equal(ls(parent.env(environment())), 'double')
})

test_that('partial attach works globally', {
    exports = c('inc', 'get_counter')
    local(mod::use(a = mod/a[inc, get_counter]), envir = .GlobalEnv)
    expect_that(search()[2L], equals(environmentName(a)))
    on.exit(detach(), add = TRUE)
    expect_equal(sort(ls(2L)), c('get_counter', 'inc'))
})

test_that('Invalid attach specifier raises error', {
    expect_error(
        mod::use(mod/a[foo, bar]),
        regexp = 'Names .* not exported by'
    )
})

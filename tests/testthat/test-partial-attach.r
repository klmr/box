context('partial attaching')

test_that('partial attach works locally', {
    a = box::use(mod/a[double])
    expect_setequal(ls(parent.env(environment())), 'double')
})

test_that('partial attach works globally', {
    exports = c('inc', 'get_counter')
    local(box::use(a = mod/a[inc, get_counter]), envir = .GlobalEnv)
    expect_equal(search()[2L], environmentName(a))
    on.exit(detach(), add = TRUE)
    expect_setequal(ls(2L), c('get_counter', 'inc'))
})

test_that('Invalid attach specifier raises error', {
    expect_box_error(
        box::use(mod/a[foo, bar]),
        regexp = 'names .* not exported by'
    )
})

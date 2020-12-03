context('hooks')

test_that('on_load hook is invoked', {
    xyz::use(mod/hooks/a)
    expect_equal(a$on_load_called, 1L)
})

test_that('on_load hook is invoked only once', {
    local({
        xyz::use(mod/hooks/a)
        expect_equal(a$on_load_called, 1L) # Still 1
    })
    local({
        xyz::use(mod/hooks/a)
        expect_equal(a$on_load_called, 1L) # STILL 1
    })
})

context('hooks')

test_that('on_load hook is invoked', {
    box::use(mod/hooks/a)
    expect_equal(a$on_load_called, 1L)
})

test_that('on_load hook is invoked only once', {
    local({
        box::use(mod/hooks/a)
        expect_equal(a$on_load_called, 1L) # Still 1
    })
    local({
        box::use(mod/hooks/a)
        expect_equal(a$on_load_called, 1L) # STILL 1
    })
})

test_that('on_unload hook is invoked during unloading', {
    self = environment()
    unload_called = 0L

    box::use(mod/hooks/a)
    a$register_unload_callback(function () self$unload_called = unload_called + 1L)

    expect_equal(unload_called, 0L)
    box::unload(a)
    expect_equal(unload_called, 1L)
})

test_that('hooks are invoked during reloading', {
    self = environment()
    unload_called = 0L

    box::use(mod/hooks/a)
    a$register_unload_callback(function () self$unload_called = unload_called + 1L)

    expect_equal(unload_called, 0L)
    box::reload(a)
    expect_equal(unload_called, 1L)
    expect_equal(a$on_load_called, 1L)
})

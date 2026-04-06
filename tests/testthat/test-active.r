context('active bindings')

test_that('active bindings can be exported', {
    box::use(mod/active)
    expect_setequal(ls(active), 'binding')
    expect_true(bindingIsActive('binding', active))
    expect_equal(active$binding, 1L)
    expect_message(active$binding, 'get')
})

test_that('active bindings can be attached', {
    box::use(mod/active[...])
    expect_true(bindingIsActive('binding', parent.env(environment())))
    expect_equal(binding, 1L)
    expect_message(binding, 'get')
})

test_that('active binding can be exported from .on_load()', {
    box::use(mod/active2)
    expect_setequal(ls(active2), 'binding')
    expect_true(bindingIsActive('binding', active2))
    expect_equal(active2$binding, 1L)
    expect_message(active2$binding, 'get')
})

test_that('active binding can be attached from .on_load()', {
    box::use(mod/active2[...])
    expect_true(bindingIsActive('binding', parent.env(environment())))
    expect_equal(binding, 1L)
    expect_message(binding, 'get')
})

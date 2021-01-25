context('names')

test_that('the global namespace has no module name', {
    expect_null(pod::name())
})

test_that('modules have a name', {
    pod::use(mod/a)
    expect_equal(a$get_modname(), 'a')
})

test_that('module names can be read inside functions', {
    pod::use(mod/a)
    expect_equal(a$get_modname2(), 'a')
})

test_that('module_name works after attaching modules', {
    # Test that #66 is fixed and that there are no regressions.

    pod::use(a = mod/a[...])
    expect_null(pod::name())

    in_globalenv({
        pod::use(a = mod/a[...])
        on.exit(pod::unload(a))
        expect_null(pod::name())
    })

    pod::use(x = mod/mod_name)

    expect_equal(x$this_module_name, 'mod_name')
    expect_equal(x$function_module_name(), 'mod_name')
    expect_equal(x$this_module_name2, 'mod_name')
    expect_equal(x$after_module_attach(), 'mod_name')
    expect_equal(x$after_package_attach(), 'mod_name')
    expect_equal(x$nested_module_name(), 'mod_name')
})

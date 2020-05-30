context('names')

test_that('the global namespace has no module name', {
    expect_null(xyz::name())
})

test_that('modules have a name', {
    xyz::use(mod/a)
    expect_equal(a$get_modname(), 'a')
})

test_that('module names can be read inside functions', {
    xyz::use(mod/a)
    expect_equal(a$get_modname2(), 'a')
})

test_that('module_name works after attaching modules', {
    # Test that #66 is fixed and that there are no regressions.

    xyz::use(a = mod/a[...])
    expect_null(xyz::name())

    in_globalenv({
        xyz::use(a = mod/a[...])
        on.exit(xyz::unload(a))
        expect_null(xyz::name())
    })

    xyz::use(x = mod/mod_name)

    expect_equal(x$this_module_name, 'mod_name')
    expect_equal(x$function_module_name(), 'mod_name')
    expect_equal(x$this_module_name2, 'mod_name')
    expect_equal(x$after_module_attach(), 'mod_name')
    expect_equal(x$after_package_attach(), 'mod_name')
    expect_equal(x$nested_module_name(), 'mod_name')
})

context('Module names')

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

    expect_that(x$this_module_name, equals('mod_name'))
    expect_that(x$function_module_name(), equals('mod_name'))
    expect_that(x$this_module_name2, equals('mod_name'))
    expect_that(x$after_module_attach(), equals('mod_name'))
    expect_that(x$after_package_attach(), equals('mod_name'))
    expect_that(x$nested_module_name(), equals('mod_name'))
})

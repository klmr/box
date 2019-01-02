context('Module names')

test_that('the global namespace has no module name', {
    expect_null(mod::name())
})

test_that('modules have a name', {
    mod::use(modules/a)
    expect_equal(a$get_modname(), 'a')
})

test_that('module names can be read inside functions', {
    mod::use(modules/a)
    expect_equal(a$get_modname2(), 'a')
})

test_that('module_name works after attaching modules', {
    # Test that #66 is fixed and that there are no regressions.

    mod::use(a = modules/a[...])
    expect_null(mod::name())

    in_globalenv({
        mod::use(a = modules/a[...])
        on.exit(mod::unload(a))
        expect_null(mod::name())
    })

    mod::use(x = modules/mod_name)

    expect_that(x$this_module_name, equals('mod_name'))
    expect_that(x$function_module_name(), equals('mod_name'))
    expect_that(x$this_module_name2, equals('mod_name'))
    expect_that(x$after_module_attach(), equals('mod_name'))
    expect_that(x$after_package_attach(), equals('mod_name'))
    expect_that(x$nested_module_name(), equals('mod_name'))
})

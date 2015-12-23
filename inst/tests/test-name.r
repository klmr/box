context('Module names')

test_that('the global namespace has no module name', {
    expect_null(module_name())
})

test_that('modules have a name', {
    a = import('a')
    expect_equal(module_name(a), 'a')
    expect_equal(a$get_modname(), 'a')
})

test_that('module names can be read inside functions', {
    a = import('a')
    expect_equal(a$get_modname2(), 'a')
})

test_that('module_name works after attaching modules', {
    # Test that #66 is fixed and that there are no regressions.

    a = import('a', attach = TRUE)
    expect_that(module_name(), is_null())

    local({
        a = import('a', attach = TRUE)
        on.exit(unload(a))
        expect_that(module_name(), is_null())
    }, envir = .GlobalEnv)

    x = import('mod_name')

    expect_that(x$this_module_name, equals('mod_name'))
    expect_that(x$function_module_name(), equals('mod_name'))
    expect_that(x$this_module_name2, equals('mod_name'))
    expect_that(x$after_module_attach(), equals('mod_name'))
    expect_that(x$after_package_attach(), equals('mod_name'))
    expect_that(x$nested_module_name(), equals('mod_name'))
})

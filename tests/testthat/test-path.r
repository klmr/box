context('Find module path relative files')

test_that('module_file works in global namespace', {
    expect_that(module_file(), equals(getwd()))
    this_file = (function() getSrcFilename(sys.call(sys.nframe())))()
    expect_true(nzchar(this_file)) # Just to make sure.
    expect_true(nchar(module_file(this_file)) > 0)
    expect_that(module_file('XXX-does-not-exist', mustWork = TRUE),
                throws_error('File not found'))
})

test_that('module_file works for module', {
    a = import('a')
    expect_true(grepl('/b$', module_file('b', module = a)))
    expect_true(grepl('/c\\.r$', module_file('c.r', module = a)))
    expect_that(length(module_file(c('b', 'c.r'), module = a)), equals(2))
})

test_that('module_base_path works', {
    # On earlier versions of “devtools”, this test reproducibly segfaulted due
    # to the call to `load_all` from within a script. This seems to be fixed now
    # with version 1.9.1.9000.
    script_path = 'modules/d.r'

    rcmd_result = rcmd(script_path)
    expect_that(rcmd_result, equals(file.path(getwd(), 'modules')))

    rscript_result = rscript(script_path)
    expect_that(rscript_result, equals(file.path(getwd(), 'modules')))
})

test_that('module_file works after attaching modules', {
    # Test that #66 is fixed and that there are no regressions.

    expected_module_file = module_file()
    import('a', attach = TRUE)
    expect_that(module_file(), equals(expected_module_file))

    local({
        expected_module_file = module_file()
        a = import('a', attach = TRUE)
        on.exit(unload(a))
        expect_that(module_file(), equals(expected_module_file))
    }, envir = .GlobalEnv)

    x = import('mod_file')
    expected_module_file = file.path(getwd(), 'modules')
    expect_that(x$this_module_file, equals(expected_module_file))
    expect_that(x$function_module_file(), equals(expected_module_file))
    expect_that(x$this_module_file2, equals(expected_module_file))
    expect_that(x$after_module_attach(), equals(expected_module_file))
    expect_that(x$after_package_attach(), equals(expected_module_file))
    expect_that(x$nested_module_file(), equals(expected_module_file))
})

test_that('regression #76 is fixed', {
    expect_error((x = import('issue76')), NA)
    expect_that(x$helper_var, equals(3))
})

test_that('regression #79 is fixed', {
    script_path = 'modules/issue79.r'
    result = tail(interactive_r(script_path), 3)

    expect_that(result[1], equals('> before; after'))
    expect_that(result[2], equals('NULL'))
    # The following assertion in particular should not fail.
    expect_that(result[3], equals('NULL'))
})

test_that('‹modules› is attached inside modules', {
    # Detach ‹modules› temporarily.
    modules_name = 'package:modules'
    modules_env = as.environment(modules_name)
    on.exit(attach(modules_env, name = modules_name))
    detach(modules_name, character.only = TRUE)

    # Verify that package is no longer attached.
    expect_false(modules_name %in% search())

    # Verify that trying to call ‹modules› functions fails.
    expect_that(source('modules/issue44.r'),
                throws_error('could not find function "module_name"'))

    # Verify that using ‹modules› functions inside module still works.
    expect_error((result = capture.output(import('issue44'))), NA)
    expect_that(result, equals('issue44'))
})

test_that('common split_path operations are working', {
    expect_correct_path_split('foo')
    expect_correct_path_split('foo/')
    expect_correct_path_split('./foo')
    expect_correct_path_split('./foo/')
    expect_correct_path_split('foo/bar')
    expect_correct_path_split('foo/bar/')
    expect_is_cwd('.')
    expect_is_cwd('./')
    expect_is_cwd('./.')
    expect_correct_path_split('~')
    expect_correct_path_split('~/foo')
})

test_that('split_path is working on Unix', {
    if (.Platform$OS.type != 'unix')
        skip('Only run on Unix')

    expect_correct_path_split('/foo/bar')
    expect_correct_path_split('/foo/bar/')
    expect_correct_path_split('/.')
})

test_that('split_path is working on Windows', {
    if (.Platform$OS.type != 'windows')
        skip('Only run on Windows')

    # Standard paths
    # UNC paths
})

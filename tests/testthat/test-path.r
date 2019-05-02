context('files relative to module')

test_that('mod::file works in global namespace', {
    expect_that(mod::file(), equals(getwd()))
    this_file = (function() getSrcFilename(sys.call(sys.nframe())))()
    expect_true(nzchar(this_file)) # Just to make sure.
    expect_true(nzchar(mod::file(this_file)))
    expect_error(
        mod::file('XXX-does-not-exist', must_work = TRUE),
        'File not found'
    )
})

test_that('mod::file works for module', {
    mod::use(mod/a)
    expect_true(grepl('/b$', mod::file('b', module = a)))
    expect_true(grepl('/c\\.r$', mod::file('c.r', module = a)))
    expect_that(length(mod::file(c('b', 'c.r'), module = a)), equals(2))
})

test_that('mod::base_path works', {
    # On earlier versions of “devtools”, this test reproducibly segfaulted due
    # to the call to `load_all` from within a script. This seems to be fixed now
    # with version 1.9.1.9000.
    script_path = 'mod/d.r'

    rcmd_result = rcmd(script_path)
    expect_paths_equal(rcmd_result, file.path(getwd(), 'mod'))

    rscript_result = rscript(script_path)
    expect_paths_equal(rscript_result, file.path(getwd(), 'mod'))
})

test_that('mod::file works after attaching modules', {
    # Test that #66 is fixed and that there are no regressions.

    expected_module_file = mod::file()
    mod::use(mod/a[...])
    expect_paths_equal(mod::file(), expected_module_file)

    modfile = in_globalenv({
        expected_module_file = mod::file()
        mod::use(a = mod/a[...])
        on.exit(mod::unload(a))
        list(actual = mod::file(), expected = expected_module_file)
    })

    expect_paths_equal(modfile$actual, modfile$expected)

    mod::use(x = mod/mod_file)
    expected_module_file = file.path(getwd(), 'mod')
    expect_paths_equal(x$this_module_file, expected_module_file)
    expect_paths_equal(x$function_module_file(), expected_module_file)
    expect_paths_equal(x$this_module_file2, expected_module_file)
    expect_paths_equal(x$after_module_attach(), expected_module_file)
    expect_paths_equal(x$after_package_attach(), expected_module_file)
    expect_paths_equal(x$nested_module_file(), expected_module_file)
})

test_that('regression #76 is fixed', {
    mod::use(x = mod/issue76)
    expect_equal(x$helper_var, 3)
})

test_that('regression #79 is fixed', {
    script_path = 'mod/issue79.r'
    result = tail(interactive_r(script_path), 3L)

    expect_equal(result[1L], '> before; after')
    expect_equal(result[2L], 'NULL')
    # The following assertion in particular should not fail.
    expect_equal(result[3L], 'NULL')
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
    skip_on_os('windows')

    expect_correct_path_split('/foo/bar')
    expect_correct_path_split('/foo/bar/')
    expect_correct_path_split('/.')
})

test_that('split_path is working on Windows', {
    if (.Platform$OS.type != 'windows') skip('Only run on Windows')

    # Standard paths
    # UNC paths
})

context('Find module path relative files')

test_that('module_file works in global namespace', {
    expect_that(module_file(), equals(getwd()))
    expect_true(nchar(module_file('run-all.r')) > 0)
    expect_that(module_file('XXX-does-not-exist', mustWork = TRUE),
                throws_error('no file found'))
})

test_that('module_file works for module', {
    a = import('a')
    expect_true(grepl('/b$', module_file('b', module = a)))
    expect_true(grepl('/c\\.r$', module_file('c.r', module = a)))
    expect_that(length(module_file(c('b', 'c.r'), module = a)), equals(2))
})

rcmd = function (script_path) {
    cmd = 'R CMD BATCH --slave --vanilla --no-restore --no-save --no-timing'
    output_file = 'output.rout'
    on.exit(unlink(output_file))
    system(paste(cmd, script_path, output_file))
    readLines(output_file)
}

rscript = function (script_path) {
    cmd = 'Rscript --slave --vanilla --no-restore --no-save'
    p = pipe(paste(cmd, script_path))
    on.exit(close(p))
    readLines(p)
}

interactive_r = function (script_path) {
    cmd = 'R --vanilla --interactive'
    output_file = 'output.rout'
    on.exit(unlink(output_file))

    local({
        p = pipe(paste(cmd, '>', output_file), 'w')
        on.exit(close(p))
        writeLines(readLines(script_path), p)
        writeLines('interactive()', p)
    })

    result = readLines(output_file)

    check_line = function (which, expected)
        if (! identical(result[which], expected))
            stop('Unexpected value ', sQuote(result[which]), ', expected ',
                 sQuote(expected), ' in `interactive_r`')

    # Ensure that code was actually run interactively.
    end = length(result)
    check_line(end - 2, '> interactive()')
    check_line(end - 1, '[1] TRUE')
    check_line(end, '> ')
    result[1 : (end - 3)]
}

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
    expect_that({x = import('issue76')},
        not(throws_error('could not find function "helper"')))
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
    expect_that((result = capture.output(import('issue44'))),
                not(throws_error('could not find function "module_name"')))
    expect_that(result, equals('issue44'))
})

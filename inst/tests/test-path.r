context('Find module path relative files')

test_that('module_file works in global namespace', {
    expect_that(module_file(), equals(getwd()))
    expect_true(nchar(module_file('run-all.r')) > 0)
    throws_error(module_file('XXX-does-not-exist', mustWork = TRUE),
                 'no file found')
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

    rcmd = 'R CMD BATCH --slave --vanilla --no-restore --no-save --no-timing'
    rscript = 'Rscript --slave --vanilla --no-restore --no-save'
    script = 'modules/d.r'

    rcmd_result = local({
        output_file = 'output.rout'
        on.exit(unlink(output_file))
        system(paste(rcmd, script, output_file))
        readLines(output_file)
    })

    test_that(rcmd_result, equals(file.path(getwd(), 'inst/test/modules')))

    rscript_result = local({
        p = pipe(paste(rscript, script))
        on.exit(close(p))
        readLines(p)
    })

    test_that(rscript_result, equals(file.path(getwd(), 'inst/test/modules')))
})

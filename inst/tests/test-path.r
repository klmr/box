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

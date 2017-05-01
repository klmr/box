context('Attach specific names only')

test_that('partial attach works locally', {
    a = import('a', attach = 'double')
    expect_that(ls(parent.env(environment())), equals('double'))
})

test_that('partial attach works globally', {
    exports <<- c('inc', 'get_counter')
    on.exit(rm(exports, envir = .GlobalEnv))
    a = local(import('a', attach = exports), envir = .GlobalEnv)
    expect_that(search()[2], equals(environmentName(a)))
    on.exit(detach(), add = TRUE)
    expect_that(sort(ls(as.environment(2))), equals(sort(exports)))
})

test_that('Invalid attach specifier raises error', {
    expect_that(import('a', attach = c('foo', 'bar')),
                throws_error('Non-existent function\\(s\\)'))
})

context('Test attach')

# File name starts with `z` so that the test is executed last.

test_that('attach works locally', {
    c = import('c')
    # c attaches `a`. So check that `a` is *not* attached here.
    expect_that(length(grep('^module:a$', search())), equals(0))
})

test_that('module can be attached to global environment', {
    searchlen = length(search())
    a = local(import('a', attach = TRUE), envir = .GlobalEnv)
    expect_that(length(search()), equals(searchlen + 1))
    message(search())
    expect_true(is_module_loaded(module_path(a)))
    expect_that(search()[2], equals(environmentName(a)))
})

test_that('module can be detached', {
    expect_that(search()[2], equals('module:a'))
    parent = as.environment(3)
    detach('module:a')
    expect_that(as.environment(2), is_identical_to(parent))
})

test_that('unloading a module detaches it', {
    parent = as.environment(2)
    a = local(import('a', attach = TRUE), envir = .GlobalEnv)
    expect_that(search()[2], equals('module:a'))
    expect_false(identical(as.environment(2), parent))

    modules::unload(a)
    expect_true(identical(as.environment(2), parent))
})

test_that('unloading a module detaches operators', {
    parent = as.environment(2)
    a = local(import('a', attach_operators = TRUE), envir = .GlobalEnv)
    expect_that(search()[2], equals('operators:a'))
    expect_false(identical(as.environment(2), parent))

    modules::unload(a)
    expect_true(identical(as.environment(2), parent))
})

test_that('reloading a module reattaches it', {
    parent = as.environment(2)
    local({a = import('a', attach = TRUE)}, envir = .GlobalEnv)

    expect_that(search()[2], equals('module:a'))
    expect_false(identical(as.environment(2), parent), 'Precondition')
    expect_true(identical(as.environment(3), parent), 'Precondition')

    local(reload(a), envir = .GlobalEnv)
    expect_false(identical(as.environment(2), parent))
    expect_true(identical(as.environment(3), parent))
    local(unload(a), envir = .GlobalEnv)
})

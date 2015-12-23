context('Basic import test')

test_that('module can be imported', {
    a = import('a')
    expect_true(is_module_loaded(module_path(a)))
    expect_true('double' %in% ls(a))
})

test_that('import works in global namespace', {
    local({
        a = import('a')
        unload(a) # To get rid of attached operators.
    }, envir = .GlobalEnv)
})

test_that('module is uniquely identified by path', {
    a = import('a')
    ba = import('b/a')
    expect_true(is_module_loaded(module_path(a)))
    expect_true(is_module_loaded(module_path(ba)))
    expect_that(module_path(a), is_not_identical_to(module_path(ba)))
    expect_true('double' %in% ls(a))
    expect_false('double' %in% ls(ba))
})

test_that('can use imported function', {
    a = import('a')
    expect_that(a$double(42), equals(42 * 2))
})

test_that('modules export all objects', {
    a = import('a')
    expect_more_than(length(lsf.str(a)), 0)
    expect_more_than(length(ls(a)), length(lsf.str(a)))
    a_namespace = environment(a$double)
    expect_that(a$counter, equals(1))
})

test_that('module can modify its variables', {
    a = import('a')
    counter = a$get_counter()
    a$inc()
    expect_that(a$get_counter(), equals(counter + 1))
})

test_that('hidden objects are not exported', {
    a = import('a')
    expect_true(exists('counter', envir = a))
    expect_false(exists('.modname', envir = a))
})

test_that('module bindings are locked', {
    a = import('a')

    expect_true(environmentIsLocked(a))
    expect_true(bindingIsLocked('get_counter', a))
    expect_true(bindingIsLocked('counter', a))

    err = try({a$counter = 2}, silent = TRUE)
    expect_that(class(err), equals('try-error'))
})

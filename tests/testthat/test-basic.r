context('Basic import test')

is_module_loaded = function (mod) {
    mod:::is_mod_loaded(attr(mod, 'info'))
}

test_teardown(clear_mods())

module_path = function (mod) {
    attr(mod, 'info')$source_path
}

test_that('module can be imported', {
    mod::use(mod/a)
    expect_true(is_module_loaded(a))
    expect_true('double' %in% ls(a))
})

test_that('import works in global namespace', {
    in_globalenv({
        mod::use(mod/a)
        expect_true(mod:::is_mod_loaded(attr(a, 'info')))
        expect_true('double' %in% ls(a))
    })
})

test_that('module is uniquely identified by path', {
    mod::use(mod/a)
    mod::use(ba = mod/b/a)
    expect_true(is_module_loaded(a))
    expect_true(is_module_loaded(ba))
    expect_not_identical(module_path(a), module_path(ba))
    expect_true('double' %in% ls(a))
    expect_false('double' %in% ls(ba))
})

test_that('can use imported function', {
    mod::use(mod/a)
    expect_that(a$double(42), equals(42 * 2))
})

test_that('modules export all objects', {
    mod::use(mod/a)
    expect_gt(length(lsf.str(a)), 0)
    expect_gt(length(ls(a)), length(lsf.str(a)))
    a_namespace = environment(a$double)
    expect_equal(a$counter, 1)
})

test_that('module can modify its variables', {
    mod::use(mod/a)
    counter = a$get_counter()
    a$inc()
    expect_equal(a$get_counter(), counter + 1)
})

test_that('hidden objects are not exported', {
    mod::use(mod/a)
    expect_true(exists('counter', envir = a))
    expect_false(exists('.modname', envir = a))
})

test_that('module bindings are locked', {
    mod::use(mod/a)

    expect_true(environmentIsLocked(a))
    expect_true(bindingIsLocked('get_counter', a))
    expect_true(bindingIsLocked('counter', a))

    err = try({a$counter = 2}, silent = TRUE)
    expect_that(class(err), equals('try-error'))
})

test_that('modules don’t need exports', {
    num_loaded_mods = function () length(ls(mod:::loaded_mods))

    num_before = num_loaded_mods()
    expect_error(mod::use(mod/c), NA)
    num_between = num_loaded_mods()
    expect_error(mod::use(mod/d), NA)
    num_after = num_loaded_mods()

    expect_equal(ls(), c('c', 'd'))
    expect_lt(num_before, num_between)
    expect_lt(num_between, num_after)
})

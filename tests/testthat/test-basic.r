context('basic')

is_module_loaded = function (mod) {
    xyz:::is_mod_loaded(attr(mod, 'info'))
}

test_teardown(clear_mods())

module_path = function (mod) {
    attr(mod, 'info')$source_path
}

test_that('module can be imported', {
    xyz::use(mod/a)
    expect_true(is_module_loaded(a))
    expect_true('double' %in% ls(a))
})

test_that('import works in global namespace', {
    in_globalenv({
        xyz::use(mod/a)
        expect_true(xyz:::is_mod_loaded(attr(a, 'info')))
        expect_true('double' %in% ls(a))
    })
})

test_that('module is uniquely identified by path', {
    xyz::use(mod/a)
    xyz::use(ba = mod/b/a)
    expect_true(is_module_loaded(a))
    expect_true(is_module_loaded(ba))
    expect_not_identical(module_path(a), module_path(ba))
    expect_true('double' %in% ls(a))
    expect_false('double' %in% ls(ba))
})

test_that('can use imported function', {
    xyz::use(mod/a)
    expect_that(a$double(42), equals(42 * 2))
})

test_that('modules export all objects', {
    xyz::use(mod/a)
    expect_gt(length(lsf.str(a)), 0L)
    expect_gt(length(ls(a)), length(lsf.str(a)))
    a_namespace = environment(a$double)
    expect_equal(a$counter, 1L)
})

test_that('module can modify its variables', {
    xyz::use(mod/a)
    counter = a$get_counter()
    a$inc()
    expect_equal(a$get_counter(), counter + 1L)
})

test_that('hidden objects are not exported', {
    xyz::use(mod/a)
    expect_true(exists('counter', envir = a))
    expect_false(exists('.modname', envir = a))
})

test_that('module bindings are locked', {
    xyz::use(mod/a)

    expect_true(environmentIsLocked(a))
    expect_true(bindingIsLocked('get_counter', a))
    expect_true(bindingIsLocked('counter', a))

    err = try({a$counter = 2L}, silent = TRUE)
    expect_that(class(err), equals('try-error'))
})

test_that('modules don’t need exports', {
    expect_equal(ls(), character(0L))
    expect_error(xyz::use(mod/c), NA)
    expect_error(capture.output(xyz::use(mod/d)), NA)
    expect_equal(ls(), c('c', 'd'))
})

test_that('global scope is not leaking into modules', {
    in_globalenv({
        x = 1L
        expect_error(xyz::use(mod/issue151), 'object .* not found')
    })
})

test_that('package exports do not leak into modules', {
    expect_true('package:stats' %in% search())
    xyz::use(mod/a)
    ns_a = attr(a, 'namespace')
    # First, ensure this is run in the right environment:
    expect_identical(get0('modname', envir = ns_a, inherits = FALSE), 'a')
    expect_identical(get0('T', envir = ns_a), TRUE)
    expect_identical(get0('t.test', envir = ns_a), NULL)
})

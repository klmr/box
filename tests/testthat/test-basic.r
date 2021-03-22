context('basic')

is_module_loaded = function (mod) {
    box:::is_mod_loaded(attr(mod, 'info'))
}

test_teardown(clear_mods())

module_path = function (mod) {
    attr(mod, 'info')$source_path
}

test_that('module can be imported', {
    box::use(mod/a)
    expect_true(is_module_loaded(a))
    expect_true('double' %in% ls(a))
})

test_that('import works in global namespace', {
    in_globalenv({
        box::use(mod/a)
        expect_true(box:::is_mod_loaded(attr(a, 'info')))
        expect_true('double' %in% ls(a))
    })
})

test_that('module is uniquely identified by path', {
    box::use(mod/a)
    box::use(ba = mod/b/a)
    expect_true(is_module_loaded(a))
    expect_true(is_module_loaded(ba))
    expect_not_identical(module_path(a), module_path(ba))
    expect_true('double' %in% ls(a))
    expect_false('double' %in% ls(ba))
})

test_that('can use imported function', {
    box::use(mod/a)
    expect_equal(a$double(42), 42 * 2)
})

test_that('modules export all objects', {
    box::use(mod/a)
    expect_gt(length(lsf.str(a)), 0L)
    expect_gt(length(ls(a)), length(lsf.str(a)))
    a_namespace = environment(a$double)
    expect_equal(a$get_counter(), 1L)
})

test_that('module can modify its variables', {
    box::use(mod/a)
    counter = a$get_counter()
    a$inc()
    expect_equal(a$get_counter(), counter + 1L)
})

test_that('hidden objects are not exported', {
    box::use(mod/a)
    ns = environment(a$get_counter)
    expect_true(exists('modname', envir = a))
    expect_true(exists('make_counter', envir = ns))
    expect_false(exists('make_counter', envir = a))
    expect_true(exists('private_modname', envir = ns))
    expect_false(exists('private_modname', envir = a))
})

test_that('module bindings are locked', {
    box::use(mod/a)

    expect_true(environmentIsLocked(a))
    expect_true(bindingIsLocked('get_counter', a))
    expect_true(bindingIsLocked('modname', a))

    err = try({a$counter = 2L}, silent = TRUE)
    expect_equal(class(err), 'try-error')
})

test_that('modules don’t need exports', {
    expect_equal(ls(), character(0L))
    expect_error(box::use(mod/no_exports), NA)
    expect_error(capture.output(box::use(mod/no_names)), NA)
    expect_setequal(ls(), c('no_exports', 'no_names'))
})

test_that('global scope is not leaking into modules', {
    in_globalenv({
        x = 1L
        expect_error(box::use(mod/issue151), 'object .* not found')
    })
})

test_that('package exports do not leak into modules', {
    expect_true('package:stats' %in% search())
    box::use(mod/a)
    ns_a = attr(a, 'namespace')
    # First, ensure this is run in the right environment:
    expect_identical(get0('modname', envir = ns_a, inherits = FALSE), 'a')
    expect_identical(get0('T', envir = ns_a), TRUE)
    expect_identical(get0('t.test', envir = ns_a), NULL)
})

test_that('partial name causes error', {
    box::use(mod/a)
    expect_error(a$double, NA)
    expect_error(a$doubl, "name 'doubl' not found in 'a'")

    # Check whether error call is correct:
    error = tryCatch(a$doubl, error = identity)
    expect_s3_class(error, 'simpleError')
    expect_identical(error$call, quote(a$doubl))
})

test_that('trailing comma is accepted', {
    expect_error(box::use(mod/a, ), NA)
    expect_error(box::use(mod/a, mod/b, ), NA)
    expect_error(box::use(mod/a[modname, double, ]), NA)
})

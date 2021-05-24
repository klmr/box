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
    expect_in('double', ls(a))
})

test_that('import works in global namespace', {
    in_globalenv({
        box::use(mod/a)
        expect_true(box:::is_mod_loaded(attr(a, 'info')))
        # `expect_in` isn’t found here.
        expect_true('double' %in% ls(a))
    })
})

test_that('module is uniquely identified by path', {
    box::use(mod/a)
    box::use(ba = mod/b/a)
    expect_true(is_module_loaded(a))
    expect_true(is_module_loaded(ba))
    expect_not_identical(module_path(a), module_path(ba))
    expect_in('double', ls(a))
    expect_not_in('double', ls(ba))
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
    expect_s3_class(err, 'try-error')
})

test_that('modules don’t need exports', {
    expect_equal(ls(), character(0L))
    expect_error(box::use(mod/no_exports), NA)
    expect_error(capture.output(box::use(mod/no_names)), NA)
    expect_setequal(ls(), c('no_exports', 'no_names'))
})

test_that('modules can be empty', {
    expect_error(box::use(mod/empty), NA)
    expect_error(box::use(mod/export_empty), NA)
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
    expect_equal(get0('modname', envir = ns_a, inherits = FALSE), 'a')
    expect_true(get0('T', envir = ns_a))
    expect_null(get0('t.test', envir = ns_a))
    expect_not_null(get0('t.test', envir = .GlobalEnv))
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

test_that('nested module can use parent', {
    box::use(mod/b/b)
    expect_true(exists('z', b))
    expect_equal(b$z, 1)
})

test_that('using legacy functions raises warning', {
    on.exit({
        box::unload(library)
        box::unload(require)
        box::unload(source)
    })

    expect_warning(box::use(mod/legacy/library), '.+library.+ inside a module')
    expect_warning(box::use(mod/legacy/require), '.+require.+ inside a module')

    expect_false(exists('source_test', envir = .GlobalEnv))
    on.exit(rm(source_test, envir = .GlobalEnv))
    expect_warning(box::use(mod/legacy/source), '.+source.+ inside a module')
    expect_true(exists('source_test', envir = .GlobalEnv))
})

test_that('legacy function warning can be silenced', {
    old_opts = options(box.warn.legacy = FALSE)
    box:::set_import_env_parent()
    on.exit({
        options(old_opts)
        box:::set_import_env_parent()
    })

    expect_warning(box::use(mod/legacy/library), NA)
    expect_warning(box::use(mod/legacy/require), NA)

    expect_false(exists('source_test', envir = .GlobalEnv))
    on.exit(rm(source_test, envir = .GlobalEnv))
    expect_warning(box::use(mod/legacy/source), NA)
    expect_true(exists('source_test', envir = .GlobalEnv))
})

test_that('r/core can be imported', {
    # All the test case logic is inside the `core_test` module.
    box::use(mod/core_test)
})

test_that('modules can be imported and exported by different local names', {
    expect_error(box::use(mod/issue211), NA)
})

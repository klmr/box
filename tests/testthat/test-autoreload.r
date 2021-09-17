context('autoreload')

tempfile_dir = function (...) {
    file = tempfile()
    dir.create(file)
    file
}

create_simple_test_module = function (dir) {
    mod = file.path(dir, 'mod')
    dir.create(mod)
    a = file.path(mod, 'a.r')
    writeLines("#' @export\nf = function () 1L", a)
}

edit_simple_test_module = function (dir) {
    a = file.path(dir, 'mod', 'a.r')
    writeLines("#' @export\nf = function () 2L", a)
}

create_dependent_test_module = function (dir) {
    mod = file.path(dir, 'mod')
    dir.create(mod)
    writeLines("#' @export\nbox::use(./b[f])", file.path(mod, 'a.r'))
    writeLines("#' @export\nf = function () 1L", file.path(mod, 'b.r'))
}

edit_dependent_test_module = function (dir) {
    mod = file.path(dir, 'mod')
    writeLines("#' @export\nf = function () 2L", file.path(mod, 'b.r'))
}

test_teardown(box:::autoreload$reset())

included = function (declaration) {
    caller = parent.frame()
    spec = parse_spec(substitute(declaration), '')
    info = find_mod(spec, caller)
    box:::autoreload$included(info)
}

test_that('no name needs to be specified', {
    expect_error(box::enable_autoreload(), NA)
})

test_that('a single name can be specified', {
    expect_error(box::enable_autoreload(include = mod/a), NA)
    expect_error(box::enable_autoreload(exclude = mod/b), NA)

    expect_error(box::autoreload_include(mod/a), NA)
    expect_error(box::autoreload_exclude(mod/a), NA)
})

test_that('multiple names can be specified', {
    expect_error(box::enable_autoreload(include = c(mod/a, mod/b)), NA)
    expect_error(box::enable_autoreload(exclude = c(mod/a, mod/b)), NA)

    expect_error(box::autoreload_include(mod/a, mod/b), NA)
    expect_error(box::autoreload_exclude(mod/a, mod/b), NA)
})

test_that('all names are included by default', {
    box::enable_autoreload()
    expect_true(included(mod/a))
    expect_true(included(mod/b))
    expect_true(included(mod/b/a))
    expect_true(included(mod/b/b))
})

test_that('included names are excluded', {
    box::enable_autoreload(include = c(mod/a, mod/b, mod/b/a))
    expect_true(included(mod/a))
    expect_true(included(mod/b))
    expect_true(included(mod/b/a))
    expect_false(included(mod/b/b))
})

test_that('excluded names are not included', {
    box::enable_autoreload(exclude = c(mod/a, mod/b, mod/b/a))
    expect_false(included(mod/a))
    expect_false(included(mod/b))
    expect_false(included(mod/b/a))
    expect_true(included(mod/b/b))
})

test_that('names can be included after being excluded', {
    box::enable_autoreload(exclude = c(mod/a, mod/b, mod/b/a))
    box::autoreload_include(mod/a, mod/b/a)
    expect_true(included(mod/a))
    expect_false(included(mod/b))
    expect_true(included(mod/b/a))
    expect_true(included(mod/b/b))
})

test_that('names can be excluded after being included', {
    box::enable_autoreload(include = c(mod/a, mod/b, mod/b/a))
    box::autoreload_exclude(mod/a, mod/b/a)
    expect_false(included(mod/a))
    expect_true(included(mod/b))
    expect_false(included(mod/b/a))
    expect_false(included(mod/b/b))
})

test_that('auto-reloading simple modules works with `box::use`', {
    dir = tempfile_dir()
    on.exit(unlink(dir, recursive = TRUE))

    old_path = options(box.path = dir)
    on.exit(options(old_path), add = TRUE)

    create_simple_test_module(dir)

    box::enable_autoreload()
    box::use(mod/a)

    expect_equal(a$f(), 1L)

    edit_simple_test_module(dir)

    box::use(mod/a)

    expect_equal(a$f(), 2L)
})

test_that('auto-reloading dependent modules works with `box::use`', {
    dir = tempfile_dir()
    on.exit(unlink(dir, recursive = TRUE))

    old_path = options(box.path = dir)
    on.exit(options(old_path), add = TRUE)

    create_dependent_test_module(dir)

    box::enable_autoreload()
    box::use(mod/a)

    expect_equal(a$f(), 1L)

    edit_dependent_test_module(dir)

    box::use(mod/a)

    expect_equal(a$f(), 2L)
})

test_that('auto-reloading simple modules works with module name', {
    dir = tempfile_dir()
    on.exit(unlink(dir, recursive = TRUE))

    old_path = options(box.path = dir)
    on.exit(options(old_path), add = TRUE)

    create_simple_test_module(dir)

    box::enable_autoreload(on_access = TRUE)
    box::use(mod/a)

    expect_equal(a$f(), 1L)

    edit_simple_test_module(dir)

    expect_equal(a$f(), 2L)
})

test_that('auto-reloading dependent modules works with module name', {
    dir = tempfile_dir()
    on.exit(unlink(dir, recursive = TRUE))

    old_path = options(box.path = dir)
    on.exit(options(old_path), add = TRUE)

    create_dependent_test_module(dir)

    box::enable_autoreload(on_access = TRUE)
    box::use(mod/a)

    expect_equal(a$f(), 1L)

    edit_dependent_test_module(dir)

    expect_equal(a$f(), 2L)
})

test_that('auto-reloading simple modules works with attached name', {
    dir = tempfile_dir()
    on.exit(unlink(dir, recursive = TRUE))

    old_path = options(box.path = dir)
    on.exit(options(old_path), add = TRUE)

    create_simple_test_module(dir)

    box::enable_autoreload(on_access = TRUE)
    box::use(mod/a[f])

    expect_equal(f(), 1L)

    edit_simple_test_module(dir)

    expect_equal(f(), 2L)
})

test_that('auto-reloading dependent modules works with attached name', {
    dir = tempfile_dir()
    on.exit(unlink(dir, recursive = TRUE))

    old_path = options(box.path = dir)
    on.exit(options(old_path), add = TRUE)

    create_dependent_test_module(dir)

    box::enable_autoreload(on_access = TRUE)
    box::use(mod/a[f])

    expect_equal(f(), 1L)

    edit_dependent_test_module(dir)

    expect_equal(f(), 2L)
})

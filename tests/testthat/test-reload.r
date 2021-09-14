context('reloading')

is_module_loaded = function (path) {
    path %in% names(box:::loaded_mods)
}

unload_all = function () {
    modenv = box:::loaded_mods
    rm(list = names(modenv), envir = modenv)
}

tempfile_dir = function (...) {
    file = tempfile()
    dir.create(file)
    file
}

create_nested_test_module = function (dir) {
    mod = file.path(dir, 'mod', 'a')
    dir.create(mod, recursive = TRUE)
    writeLines("#' @export\nbox::use(./sub)", file.path(mod, '__init__.r'))
    writeLines("#' @export\nvalue = 1L", file.path(mod, 'sub.r'))
}

edit_nested_test_module = function (dir) {
    mod = file.path(dir, 'mod', 'a')
    writeLines("#' @export\nvalue = 2L", file.path(mod, 'sub.r'))
}

test_that('module can be reloaded', {
    # Required since other tests have side-effects.
    # Tear-down would be helpful here, but not supported by testthat.
    unload_all()

    box::use(mod/a)
    expect_equal(length(box:::loaded_mods), 1L)
    counter = a$get_counter()
    a$inc()
    expect_equal(a$get_counter(), counter + 1L)

    box::reload(a)
    expect_true(is_module_loaded(box:::path(a)))
    expect_length(box:::loaded_mods, 1L)
    expect_equal(a$get_counter(), counter)
})

test_that('reload checks its arguments', {
    expect_error(box::reload(123))
    expect_error(box::reload(foo))
    box::use(mod/a)
    expect_error(box::reload((a)))
})

test_that('reload includes module dependencies', {
    # This test case actually edits a dependency and reloads the edit. The
    # purpose of this is to ensure that reloading doesn’t merely call `.on_load`
    # again, but actually does reload the changes from disk.
    dir = tempfile_dir()
    on.exit(unlink(dir, recursive = TRUE))

    old_path = options(box.path = dir)
    on.exit(options(old_path), add = TRUE)

    create_nested_test_module(dir)

    box::use(mod/a)

    expect_equal(a$sub$value, 1L)

    edit_nested_test_module(dir)

    box::reload(a)

    expect_equal(a$sub$value, 2L)

    # To do:
    # * modules with compiled source,
    # * tricky packages loaded as modules, e.g. packages that call
    #   system.file(), and alike, and
    # * modules with S4 classes/object,
})

test_that('reload includes transitive dependencies', {
    # Unlike in the previous test, this test uses `.on_load` as an indicator of
    # reloading, to keep things simpler.
    box::use(mod/reload/a)
    expect_messages(
        box::reload(a),
        has = c('^c unloaded', '^c loaded')
    )
})

test_that('reload of transitive imports skips packages', {
    box::use(mod/reload/pkg)
    expect_error(box::reload(pkg), NA)
})

test_that('`reload` shows expected errors', {
    old_opts = options(useFancyQuotes = FALSE)
    on.exit(options(old_opts))

    expect_box_error(
        box::reload(mod/a),
        '"reload" expects a module object, got "mod/a"'
    )
    expect_box_error(
        box::reload(./a),
        '"reload" expects a module object, got "./a"'
    )
    expect_box_error(box::reload(na), 'object "na" not found')

    x = 1L
    expect_box_error(
        box::reload(x),
        '"reload" expects a module object, got "x", which is of type "integer" instead'
    )
})

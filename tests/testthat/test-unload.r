context('unloading')

is_module_loaded = function (path) {
    path %in% names(box:::loaded_mods)
}

test_that('module can be unloaded', {
    box::use(mod/a)
    path = box:::path(a)
    expect_true(is_module_loaded(path))
    box::unload(a)
    expect_false(is_module_loaded(path))
    expect_false(exists('a', inherits = FALSE))
})

test_that('unloaded module can be reloaded', {
    box::use(mod/a)
    box::unload(a)
    box::use(mod/a)
    expect_true(is_module_loaded(box:::path(a)))
    expect_true(exists('a', inherits = FALSE))
})

test_that('unload checks its arguments', {
    expect_error(box::unload(123))
    expect_error(box::unload(foo))
    box::use(mod/a)
    expect_error(box::unload((a)))
})

test_that('unloading calls unload hook', {
    box::use(mod/reload/a)
    expect_message(box::unload(a), '^a unloaded')
})

test_that('unloading does not unload dependencies', {
    box::use(mod/reload/a)
    expect_messages(
        box::unload(a),
        has = '^a unloaded',
        has_not = '^c unloaded'
    )
})

test_that('`unload` shows expected errors', {
    old_opts = options(useFancyQuotes = FALSE)
    on.exit(options(old_opts))

    expect_box_error(
        box::unload(mod/a),
        '"unload" expects a module object, got "mod/a"'
    )
    expect_box_error(
        box::unload(./a),
        '"unload" expects a module object, got "./a"'
    )
    expect_box_error(box::unload(na), 'object "na" not found')

    x = 1L
    expect_box_error(
        box::unload(x),
        '"unload" expects a module object, got "x", which is of type "integer" instead'
    )
})

test_that('purging cache marks modules as unloaded', {
    box::use(mod/a)
    path = box:::path(a)

    expect_true(is_module_loaded(path))
    box::purge_cache()
    expect_false(is_module_loaded(path))
})

test_that('after purging the cache, modules get reloaded', {
    box::use(mod/a)
    a$inc()
    counter = a$get_counter()

    box::purge_cache()
    box::use(mod/a)
    expect_not_equal(a$get_counter(), counter)
})

test_that('purging the cache executes `.on_unload` hooks', {
    box::use(mod/reload/a)
    expect_message(box::purge_cache(), '^a unloaded')
})

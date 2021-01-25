context('find_mod')

test_use = function (...) {
    call = match.call()
    parse_spec(call[[2L]], names(call[-1L]))
}

test_that('"./" can only be used as a prefix', {
    expect_error(test_use(./a), NA)
    expect_error(test_use(.././a))
    expect_error(test_use(a/./b))
    expect_error(test_use(a/.))
    expect_error(test_use(a/b/./c))
})

test_that('"../" can only be used as a prefix', {
    expect_error(test_use(../a), NA)
    expect_error(test_use(../../a), NA)
    expect_error(test_use(./../a))
    expect_error(test_use(a/../b))
    expect_error(test_use(../a/../b))
    expect_error(test_use(a/..))
    expect_error(test_use(a/b/../c))
})

test_that('local path is searched globally', {
    old_opts = options(pod.path = NULL)
    on.exit(options(old_opts))

    expect_paths_equal(mod_search_path(environment()), getwd())
})

test_that('local path is searched in module', {
    old_opts = options(pod.path = NULL)
    on.exit(options(old_opts))

    pod::use(rel = mod/nested/rel_import)
    nested_path = file.path(getwd(), 'mod', 'nested')

    expect_paths_equal(rel$global_path, nested_path)
    expect_paths_equal(rel$path_in_fun(), nested_path)
    expect_paths_equal(rel$path_in_nested_fun(), nested_path)
})

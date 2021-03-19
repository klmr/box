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
    old_opts = options(box.path = NULL)
    on.exit(options(old_opts))

    expect_paths_equal(mod_search_path(environment()), getwd())
})

test_that('local path is searched in module', {
    old_opts = options(box.path = NULL)
    on.exit(options(old_opts))

    box::use(rel = mod/nested/rel_import)
    nested_path = file.path(getwd(), 'mod', 'nested')

    expect_paths_equal(rel$global_path, nested_path)
    expect_paths_equal(rel$path_in_fun(), nested_path)
    expect_paths_equal(rel$path_in_nested_fun(), nested_path)
})

test_that('all module file candidates are found', {
    # See <https://github.com/klmr/box/issues/174>
    spec = parse_spec(quote(a/b), '')
    paths = c('x', 'y')
    candidates = mod_file_candidates(spec, paths)
    expected = c(
        'x/a/b.r',
        'x/a/b.R',
        'x/a/b/__init__.r',
        'x/a/b/__init__.R',
        'y/a/b.r',
        'y/a/b.R',
        'y/a/b/__init__.r',
        'y/a/b/__init__.R'
    )
    expect_setequal(unlist(candidates), expected)
})

test_that('script path can be set manually', {
    on.exit(box::set_script_path())

    expect_paths_equal(script_path(), getwd())

    box::set_script_path('mod/b/a.r')
    expect_equal(script_path(), 'mod/b')
})

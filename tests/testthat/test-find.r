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

    path = utils::tail(mod_search_path(environment()), 1L)
    expect_paths_equal(path, getwd())
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

    expect_paths_equal(module_path(), getwd())

    box::set_script_path('mod/b/a.r')
    expect_equal(module_path(), 'mod/b')
})

test_that('script path can be queried', {
    path = 'some/script.r'
    box::set_script_path(path)
    expect_equal(box::script_path(), path)
    expect_equal(box::set_script_path(), path)
    expect_null(box::script_path())
})

test_that('can execute a script with spaces in path', {
    # Generate the test case dynamically since `R CMD check` complains if there
    # are paths with spaces in the package source directory.
    path = 'support/path with spaces'
    dir.create(path)
    on.exit(unlink(path, recursive = TRUE))
    writeLines(c(
        '.on_load = function (ns) cat("path with spaces\\n")',
        'box::export()'
    ), file.path(path, 'a.r'))
    writeLines('box::use(./a)', file.path(path, 'script.r'))

    rscript_out = rscript(file.path(path, 'script.r'))
    expect_equal(rscript_out, 'path with spaces')
})

test_that('modules are found during Shiny startup', {
    script_path = rscript('support/run-shiny.r')
    expect_paths_equal(script_path, 'support/shiny-app')
})

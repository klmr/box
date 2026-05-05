context('relative imports')

test_that('Imports are absolute by default', {
    old_opts = options(box.path = getwd())
    on.exit(options(old_opts))

    old_env = Sys.getenv('R_BOX_PATH', NA)
    if (!is.na(old_env)) {
        Sys.unsetenv('R_BOX_PATH')
        on.exit(Sys.setenv(R_BOX_PATH = old_env), add = TRUE)
    }

    box::use(mod/nested/relative_a)
    expect_equal(relative_a$a_which(), '/a')
})

test_that('Relative import are always local', {
    old_opts = options(box.path = getwd())
    on.exit(options(old_opts))

    old_env = Sys.getenv('R_BOX_PATH', NA)
    if (!is.na(old_env)) {
        Sys.unsetenv('R_BOX_PATH')
        on.exit(Sys.setenv(R_BOX_PATH = old_env), add = TRUE)
    }

    box::use(mod/nested/relative_a)
    expect_equal(relative_a$local_a_which(), 'nested/a')
})

context('attaching')

# File name starts with `z` so that the test is executed last.

test_mod_envname = 'mod:mod/a'

test_that('‘box’ cannot be attached', {
    skip_on_cran()
    detach('package:box')
    # Temporarily unset environment indicating that we’re inside testing mode:
    envs = c('_R_CHECK_PACKAGE_NAME_', 'R_TESTS')
    old_env = Sys.getenv(envs)
    on.exit({
        do.call('Sys.setenv', as.list(old_env))
        Sys.unsetenv('R_BOX_TEST_ALLOW_DEVTOOLS')
    })
    Sys.unsetenv(envs)
    Sys.setenv(R_BOX_TEST_ALLOW_DEVTOOLS = 'TRUE')
    expect_error(attachNamespace('box'), 'Please consult the user guide at `vignette\\("box", package = "box"\\)`')
})

test_that('attach works locally inside module', {
    box::use(mod/no_exports)
    # `no_exports` attaches `a`. So check that `a` is *not* attached here.
    expect_not_in(test_mod_envname, search())
    expect_false(exists('modname'))
})

test_that('attach works locally inside function', {
    f = function () {
        box::use(mod/a[...])
        expect_true(exists('modname'))
    }

    f()
    expect_false(exists('modname'))
})

test_that('module can be attached to global environment', {
    .GlobalEnv$searchlen = length(search())
    in_globalenv({
        box::use(a = mod/a[...])
        mod_path = box:::path(a)
        expect_length(search(), searchlen + 1L)
        expect_true(mod_path %in% names(box:::loaded_mods))
        expect_equal(search()[2L], environmentName(a))
    })
    rm(searchlen, envir = .GlobalEnv)
})

test_that('module can be detached', {
    expect_equal(search()[2L], test_mod_envname)
    parent = as.environment(3L)
    detach(test_mod_envname, character.only = TRUE)
    expect_identical(as.environment(2L), parent)
})

test_that('hidden names can be attached', {
    expect_false(exists('.hidden'))
    box::use(mod/a[...])
    expect_true(exists('.hidden'))
})

test_that('unloading a module detaches it', {
    parent = as.environment(2L)
    local(box::use(a = mod/a[...]), .GlobalEnv)
    expect_equal(search()[2L], test_mod_envname)
    expect_not_identical(as.environment(2L), parent)

    in_globalenv(box::unload(a))
    expect_identical(as.environment(2L), parent)
})

test_that('unloading a local module detaches it', {
    local({
        old_parent = parent.env(environment())
        box::use(a = mod/a[...])
        new_parent = parent.env(environment())
        expect_not_identical(old_parent, new_parent)
        expect_identical(old_parent, parent.env(new_parent))
        box::reload(a)
        expect_not_identical(old_parent, parent.env(environment()))
        expect_not_identical(new_parent, parent.env(environment()))
        expect_identical(old_parent, parent.env(parent.env(environment())))
    })
})

test_that('reloading a module reattaches it', {
    parent = as.environment(2L)
    local(box::use(a = mod/a[...]), .GlobalEnv)

    expect_equal(search()[2L], test_mod_envname)
    expect_not_identical(as.environment(2L), parent, 'Precondition')
    expect_identical(as.environment(3L), parent, 'Precondition')

    in_globalenv(box::reload(a))
    expect_not_identical(as.environment(2L), parent)
    expect_identical(as.environment(3L), parent)
    in_globalenv(box::unload(a))
})

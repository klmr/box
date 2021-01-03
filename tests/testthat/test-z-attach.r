context('attaching')

# File name starts with `z` so that the test is executed last.

test_mod_envname = 'mod:mod/a'

test_that('attach works locally', {
    xyz::use(mod/no_exports)
    # `no_exports` attaches `a`. So check that `a` is *not* attached here.
    expect_false(test_mod_envname %in% search())
})

test_that('module can be attached to global environment', {
    .GlobalEnv$searchlen = length(search())
    in_globalenv({
        xyz::use(a = mod/a[...])
        mod_path = xyz::path(a)
        expect_equal(length(search()), searchlen + 1L)
        expect_true(mod_path %in% names(xyz:::loaded_mods))
        expect_equal(search()[2L], environmentName(a))
    })
})

test_that('module can be detached', {
    expect_equal(search()[2L], test_mod_envname)
    parent = as.environment(3L)
    detach(test_mod_envname, character.only = TRUE)
    expect_identical(as.environment(2L), parent)
})

test_that('unloading a module detaches it', {
    parent = as.environment(2L)
    local(xyz::use(a = mod/a[...]), .GlobalEnv)
    expect_equal(search()[2L], test_mod_envname)
    expect_not_identical(as.environment(2L), parent)

    in_globalenv(xyz::unload(a))
    expect_identical(as.environment(2L), parent)
})

test_that('unloading a local module detaches it', {
    (function () {
        old_parent = parent.env(environment())
        xyz::use(a = mod/a[...])
        new_parent = parent.env(environment())
        expect_not_identical(old_parent, new_parent)
        expect_identical(old_parent, parent.env(new_parent))
        xyz::reload(a)
        expect_not_identical(old_parent, parent.env(environment()))
        expect_not_identical(new_parent, parent.env(environment()))
        expect_identical(old_parent, parent.env(parent.env(environment())))
    })()
})

test_that('reloading a module reattaches it', {
    parent = as.environment(2L)
    local(xyz::use(a = mod/a[...]), .GlobalEnv)

    expect_equal(search()[2L], test_mod_envname)
    expect_not_identical(as.environment(2L), parent, 'Precondition')
    expect_identical(as.environment(3L), parent, 'Precondition')

    in_globalenv(xyz::reload(a))
    expect_not_identical(as.environment(2L), parent)
    expect_identical(as.environment(3L), parent)
    in_globalenv(xyz::unload(a))
})

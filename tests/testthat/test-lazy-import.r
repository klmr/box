context('lazy imports')

test_that('lazy package imports are not loaded until used', {
    unloadNamespace('devtools')
    expect_false(isNamespaceLoaded('devtools'))
    box::use(~devtools)
    expect_in('devtools', ls())
    expect_false(isNamespaceLoaded('devtools'))
    expect_in('load_all', ls(devtools))
    expect_true(isNamespaceLoaded('devtools'))
})

test_that('lazy package imports can be aliased', {
    unloadNamespace('devtools')
    expect_not_in('dev', ls())
    box::use(dev = ~devtools)
    expect_in('dev', ls())
    expect_not_in('devtools', ls())
    expect_false(isNamespaceLoaded('devtools'))
    expect_identical(dev$load_all, devtools::load_all)
    expect_true(isNamespaceLoaded('devtools'))
})

test_that('lazy package imports are evaluated only once', {
    box::use(~devtools)
    first = devtools
    second = devtools
    expect_identical(first, second)
})

test_that('lazy imports with attach lists are still attached', {
    expect_not_in('load_all', ls(parent.env(environment())))
    box::use(~devtools[load_all])
    expect_in('load_all', ls(parent.env(environment())))
})

test_that('lazy module imports still work', {
    box::use(~mod/a)
    expect_in('a', ls())
    expect_equal(a$double(2), 4)
})

test_that('lazy module imports are not loaded until used', {
    clear_mods()
    info = box:::find_mod(box:::parse_spec(quote(mod/a), ''), environment())
    expect_false(box:::is_mod_loaded(info))
    box::use(~mod/a)
    expect_in('a', ls())
    expect_false(box:::is_mod_loaded(info))
    expect_equal(a$double(2), 4)
    expect_true(box:::is_mod_loaded(info))
})

test_that('lazy attached names, are not loaded until used', {
    unloadNamespace('devtools')
    box::use(~devtools[load_all, unload])
    expect_in('load_all', ls(parent.env(environment())))
    expect_in('unload', ls(parent.env(environment())))
    expect_false(isNamespaceLoaded('devtools'))
    expect_identical(load_all, devtools::load_all)
    expect_true(isNamespaceLoaded('devtools'))
})

test_that('renaming lazy attached names are allowed', {
    unloadNamespace('devtools')
    box::use(~devtools[l_all = load_all])
    expect_identical(l_all, devtools::load_all)
})

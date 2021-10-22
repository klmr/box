context('spec parser')

test_use = function (...) {
    call = match.call()
    parse_spec(call[[2L]], names(call)[[2L]] %||% '')
}

is_mod_spec = function (x) {
    inherits(x, 'box$mod_spec')
}

is_pkg_spec = function (x) {
    inherits(x, 'box$pkg_spec')
}

test_that('modules without attaching can be parsed', {
    m = test_use(foo/bar)
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'bar')
    expect_equal(m$prefix, 'foo')
    expect_equal(m$alias, 'bar')
    expect_false(m$explicit)
    expect_null(m$attach)
})

test_that('parse errors are correctly handled', {
    expect_box_error(
        test_use(foo/bar[]),
        '^expected at least one name in attach list'
    )
})

test_that('fully qualified names can be nested', {
    m = test_use(foo/bar/baz)
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'baz')
    expect_equal(m$prefix, c('foo', 'bar'))
    expect_equal(m$alias, 'baz')
    expect_false(m$explicit)
    expect_null(m$attach)
})

test_that('imports can be relative', {
    m = test_use(./foo)
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$prefix, '.')
    expect_null(m$attach)

    m = test_use(./foo[bar])
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$prefix, '.')
    expect_equal(m$attach, c(bar = 'bar'))

    m = test_use(..)
    expect_true(is_mod_spec(m))
    expect_equal(m$name, '.')
    expect_equal(m$prefix, '..')
    expect_null(m$attach)

    m = test_use(..[foo])
    expect_true(is_mod_spec(m))
    expect_equal(m$name, '.')
    expect_equal(m$prefix, '..')
    expect_equal(m$attach, c(foo = 'foo'))

    m = test_use(../foo)
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$prefix, '..')
    expect_null(m$attach)

    m = test_use(../foo[bar])
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$prefix, '..')
    expect_equal(m$attach, c(bar = 'bar'))
})

test_that('`./` can only be used as a prefix', {
    expect_box_error(test_use(a/./b), 'can only be used as a prefix')
    expect_box_error(test_use(././b), 'can only be used as a prefix')
    expect_box_error(test_use(a/b/.), 'can only be used as a prefix')
    expect_box_error(test_use(a/./b[foo]), 'can only be used as a prefix')
    expect_box_error(test_use(././b[foo]), 'can only be used as a prefix')
    expect_box_error(test_use(a/b/.[foo]), 'can only be used as a prefix')

    expect_error(test_use(../../b), NA)
    expect_box_error(test_use(.././b), 'can only be used as a prefix')
    expect_box_error(test_use(../.), 'can only be used as a prefix')
    expect_error(test_use(../../b[foo]), NA)
    expect_box_error(test_use(.././b[foo]), 'can only be used as a prefix')
    expect_box_error(test_use(../.[foo]), 'can only be used as a prefix')

    expect_box_error(test_use(a/../b), 'can only be used as a prefix')
    expect_box_error(test_use(a/b/..), 'can only be used as a prefix')
    expect_box_error(test_use(a/../b[foo]), 'can only be used as a prefix')
    expect_box_error(test_use(a/b/..[foo]), 'can only be used as a prefix')

    expect_box_error(test_use(./../b), 'can only be used as a prefix')
    expect_box_error(test_use(./..), 'can only be used as a prefix')
    expect_box_error(test_use(./../b[foo]), 'can only be used as a prefix')
    expect_box_error(test_use(./..[foo]), 'can only be used as a prefix')
})

test_that('modules can have explicit aliases', {
    m = test_use(qux = foo/bar)
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'bar')
    expect_equal(m$prefix, 'foo')
    expect_equal(m$alias, 'qux')
    expect_true(m$explicit)
    expect_null(m$attach)
})

test_that('modules can have specific exports', {
    m = test_use(foo/bar[sym1, sym2])
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'bar')
    expect_equal(m$prefix, 'foo')
    expect_equal(m$alias, 'bar')
    expect_false(m$explicit)
    expect_equal(m$attach, c(sym1 = 'sym1', sym2 = 'sym2'))
})

test_that('modules with alias can have specific exports', {
    m = test_use(baz = foo/bar[sym1, sym2])
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'bar')
    expect_equal(m$prefix, 'foo')
    expect_equal(m$alias, 'baz')
    expect_true(m$explicit)
    expect_equal(m$attach, c(sym1 = 'sym1', sym2 = 'sym2'))
})

test_that('modules can export everything', {
    m = test_use(foo/bar[...])
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'bar')
    expect_equal(m$prefix, 'foo')
    expect_equal(m$alias, 'bar')
    expect_false(m$explicit)
    expect_true(is.na(m$attach))
})

test_that('attached names can have aliases', {
    m = test_use(foo/bar[alias1 = sym1, sym2])
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'bar')
    expect_equal(m$prefix, 'foo')
    expect_equal(m$alias, 'bar')
    expect_false(m$explicit)
    expect_equal(m$attach, c(alias1 = 'sym1', sym2 = 'sym2'))
})

test_that('exports and aliases can’t be duplicated', {
    expect_box_error(test_use(foo/bar[a, b, a]), 'duplicate names')
    expect_box_error(test_use(foo/bar[x = a, y = b, x = c]), 'duplicate names')
    expect_box_error(test_use(foo/bar[..., ...]), 'duplicate names')

    m = test_use(foo/bar[x = a, a = b, b])
    expect_true(is_mod_spec(m))
    expect_equal(m$attach, c(x = 'a', a = 'b', b = 'b'))
})

test_that('wildcards can be mixed with aliases', {
    m = test_use(foo/bar[x = a, y = b, ...])
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'bar')
    expect_equal(m$prefix, 'foo')
    expect_equal(m$alias, 'bar')
    expect_false(m$explicit)
    expect_equal(m$attach, c(x = 'a', y = 'b', ... = NA_character_))
})

test_that('wildcard can’t have alias', {
    expect_box_error(test_use(foo/bar[x = ...]), 'cannot be aliased')
    expect_box_error(test_use(foo/bar[x = a, y = ...]), 'cannot be aliased')
})

# … the same for packages.

test_that('packages without attaching can be parsed', {
    m = test_use(foo)
    expect_true(is_pkg_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$alias, 'foo')
    expect_false(m$explicit)
    expect_null(m$attach)
})

test_that('packages can have explicit alias', {
    m = test_use(bar = foo)
    expect_true(is_pkg_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$alias, 'bar')
    expect_true(m$explicit)
    expect_null(m$attach)
})

test_that('packages can have specific exports', {
    m = test_use(foo[sym1, sym2])
    expect_true(is_pkg_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$alias, 'foo')
    expect_false(m$explicit)
    expect_equal(m$attach, c(sym1 = 'sym1', sym2 = 'sym2'))
})

test_that('packages with alias can have specific exports', {
    m = test_use(bar = foo[sym1, sym2])
    expect_true(is_pkg_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$alias, 'bar')
    expect_true(m$explicit)
    expect_equal(m$attach, c(sym1 = 'sym1', sym2 = 'sym2'))
})

test_that('packages can export everything', {
    m = test_use(foo[...])
    expect_true(is_pkg_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$alias, 'foo')
    expect_false(m$explicit)
    expect_true(is.na(m$attach))
})

test_that('attached names in packages can have aliases', {
    m = test_use(foo[alias1 = sym1, sym2])
    expect_true(is_pkg_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$alias, 'foo')
    expect_false(m$explicit)
    expect_equal(m$attach, c(alias1 = 'sym1', sym2 = 'sym2'))
})

test_that('exports and aliases can’t be duplicated', {
    expect_box_error(test_use(foo[a, b, a]), 'duplicate names')
    expect_box_error(test_use(foo[x = a, y = b, x = c]), 'duplicate names')
    expect_box_error(test_use(foo[..., ...]), 'duplicate names')

    m = test_use(foo[x = a, a = b, b])
    expect_true(is_pkg_spec(m))
    expect_equal(m$attach, c(x = 'a', a = 'b', b = 'b'))
})

test_that('wildcards can be mixed with aliases', {
    m = test_use(foo[x = a, y = b, ...])
    expect_true(is_pkg_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$alias, 'foo')
    expect_false(m$explicit)
    expect_equal(m$attach, c(x = 'a', y = 'b', ... = NA_character_))
})

test_that('wildcard can’t have alias', {
    expect_box_error(test_use(foo[x = ...]), 'cannot be aliased')
    expect_box_error(test_use(foo[x = a, y = ...]), 'cannot be aliased')
})

test_that('trailing comma is accepted', {
    expect_error(test_use(mod/a, ), NA)
    expect_error(test_use(mod/a, mod/b, ), NA)
    expect_error(test_use(mod/a[modname, double, ]), NA)
})

test_that('aliases need a name', {
    expect_box_error(test_use(alias =), 'alias without a name provided in use declaration')
    expect_box_error(box::use(mod/a, alias =), 'alias without a name provided in use declaration')
    expect_box_error(test_use(foo/bar[alias =, y]), 'alias without a name provided in attach list')
    expect_box_error(test_use(foo/bar[x, alias =]), 'alias without a name provided in attach list')
})

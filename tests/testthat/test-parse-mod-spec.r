context('mod spec parser test')

test_that('modules without attaching can be parsed', {
    m = parse_mod_spec(foo/bar)
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'bar')
    expect_equal(m$prefix, 'foo')
    expect_equal(m$alias, 'bar')
    expect_false(m$explicit)
    expect_null(m$attach)
})

test_that('parse errors are correctly handled', {
    expect_error(
        parse_mod_spec(foo/bar[]),
        '^Expected at least one identifier in attach list'
    )
})

test_that('fully qualified names can be nested', {
    m = parse_mod_spec(foo/bar/baz)
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'baz')
    expect_equal(m$prefix, c('foo', 'bar'))
    expect_equal(m$alias, 'baz')
    expect_false(m$explicit)
    expect_null(m$attach)
})

test_that('modules can have explicit aliases', {
    m = parse_mod_spec(qux = foo/bar)
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'bar')
    expect_equal(m$prefix, 'foo')
    expect_equal(m$alias, 'qux')
    expect_true(m$explicit)
    expect_null(m$attach)
})

test_that('modules can have specific exports', {
    m = parse_mod_spec(foo/bar[sym1, sym2])
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'bar')
    expect_equal(m$prefix, 'foo')
    expect_equal(m$alias, 'bar')
    expect_false(m$explicit)
    expect_equal(m$attach, c(sym1 = 'sym1', sym2 = 'sym2'))
})

test_that('modules with alias can have specific exports', {
    m = parse_mod_spec(baz = foo/bar[sym1, sym2])
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'bar')
    expect_equal(m$prefix, 'foo')
    expect_equal(m$alias, 'baz')
    expect_true(m$explicit)
    expect_equal(m$attach, c(sym1 = 'sym1', sym2 = 'sym2'))
})

test_that('modules can export everything', {
    m = parse_mod_spec(foo/bar[...])
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'bar')
    expect_equal(m$prefix, 'foo')
    expect_equal(m$alias, 'bar')
    expect_false(m$explicit)
    expect_true(m$attach)
})

test_that('attached names can have aliases', {
    m = parse_mod_spec(foo/bar[alias1 = sym1, sym2])
    expect_true(is_mod_spec(m))
    expect_equal(m$name, 'bar')
    expect_equal(m$prefix, 'foo')
    expect_equal(m$alias, 'bar')
    expect_false(m$explicit)
    expect_equal(m$attach, c(alias1 = 'sym1', sym2 = 'sym2'))
})

# … the same for packages.

test_that('packages without attaching can be parsed', {
    m = parse_mod_spec(foo)
    expect_true(is_pkg_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$alias, 'foo')
    expect_false(m$explicit)
    expect_null(m$attach)
})

test_that('packages can have explicit alias', {
    m = parse_mod_spec(bar = foo)
    expect_true(is_pkg_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$alias, 'bar')
    expect_true(m$explicit)
    expect_null(m$attach)
})

test_that('packages can have specific exports', {
    m = parse_mod_spec(foo[sym1, sym2])
    expect_true(is_pkg_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$alias, 'foo')
    expect_false(m$explicit)
    expect_equal(m$attach, c(sym1 = 'sym1', sym2 = 'sym2'))
})

test_that('packages with alias can have specific exports', {
    m = parse_mod_spec(bar = foo[sym1, sym2])
    expect_true(is_pkg_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$alias, 'bar')
    expect_true(m$explicit)
    expect_equal(m$attach, c(sym1 = 'sym1', sym2 = 'sym2'))
})

test_that('packages can export everything', {
    m = parse_mod_spec(foo[...])
    expect_true(is_pkg_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$alias, 'foo')
    expect_false(m$explicit)
    expect_true(m$attach)
})

test_that('attached names in packages can have aliases', {
    m = parse_mod_spec(foo[alias1 = sym1, sym2])
    expect_true(is_pkg_spec(m))
    expect_equal(m$name, 'foo')
    expect_equal(m$alias, 'foo')
    expect_false(m$explicit)
    expect_equal(m$attach, c(alias1 = 'sym1', sym2 = 'sym2'))
})

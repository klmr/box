context('format')

test_that('literal strings are unchanged', {
    expect_equal(fmt('this is a test'), 'this is a test')
    expect_equal(fmt('this', 'is', 'a', 'test'), 'thisisatest')
    expect_equal(fmt(c('this', 'is'), 'a', 'test'), 'thisisatest')
})

test_that('escaping works', {
    expect_equal(fmt('a {{test}}'), 'a {test}')
    expect_equal(fmt('a {{{{test}}'), 'a {{test}')
})

test_that('interpolation works', {
    expect_equal(fmt('a {"test"}'), 'a test')
    expect_equal(fmt('a {{{"test"}}}'), 'a {test}')
    x = 'test'
    expect_equal(fmt('a {x}'), 'a test')
    expect_equal(fmt('a {x}', x = 42L), 'a 42')
})

# test_that('escaping works inside interpolation', {
#     expect_equal(fmt('{"{{test"}'), '{test')
#     expect_equal(fmt('{"test}}"}'), 'test}')
# })

test_that('format modifiers work', {
    expect_equal(fmt('a {"test";"}'), sprintf('a %s', dQuote('test')))
    expect_equal(fmt("a {'test';'}"), sprintf('a %s', sQuote('test')))
    expect_equal(fmt('pi = {pi;.2f}'), sprintf('pi = %.2f', pi))
    x = 1 : 3
    expect_equal(fmt('x = {x}'), 'x = 1, 2, 3')
    expect_equal(fmt('{x;"}'), toString(dQuote(x)))
})

test_that('invalid formats raise an error', {
    expect_box_error(
        fmt('{12;1?}'),
        sprintf('unrecognized format modifier %s', dQuote('1\\?'))
    )
})

test_that('deparsed expression forms a single string', {
    expr = quote(long_call(with + some, "arguments in it", that_total, over, 60L - ...chars))
    actual = fmt('{expr;"}')

    expect_equal(actual, dQuote(deparse1(expr)))
})

test_that('real use-cases from this package implementation work', {
    old_opts = options(useFancyQuotes = FALSE)
    on.exit(options(old_opts))

    # errors.r

    call = call('foo', 'bar', x = 1L)
    error = simpleError('test', call)
    expect_equal(
        fmt(
            '{msg}\n(inside {calls})',
            msg = conditionMessage(error),
            calls = paste(dQuote(deparse(conditionCall(error))), collapse = '\n')
        ),
        'test\n(inside "foo("bar", x = 1L)")'
    )

    fmt = '?'
    expect_equal(
        fmt('unrecognized format modifier {fmt;"}'),
        'unrecognized format modifier "?"'
    )

    # export.r

    expect_equal(
        fmt('{"export";"} can only be called from inside a module'),
        '"export" can only be called from inside a module'
    )

    name = quote(test)
    expect_equal(
        fmt(
            '{"export()";"} requires a list of unquoted names; ',
            '{name;"} is not a name'
        ),
        '"export()" requires a list of unquoted names; "test" is not a name',
    )

    expect_equal(
        fmt(
            'Invalid attempt to export names from an incompletely ',
            'loaded, cyclic import (module {name;"}) in line {line}.',
            name = 'foo/test',
            line = 42L
        ),
        'Invalid attempt to export names from an incompletely loaded, cyclic import (module "foo/test") in line 42.'
    )

    expect_equal(
        fmt(
            'The {"@export";"} tag may only be applied to assignments or ',
            '{"use";"} declarations.\n',
            'Used incorrectly in line {location}:\n',
            '    {paste(code, collapse = \'\n    \')}',
            code = c('foo', 'bar'),
            location = 42L
        ),
        'The "@export" tag may only be applied to assignments or "use" declarations.\nUsed incorrectly in line 42:\n    foo\n    bar'
    )

    # help.r

    topic = quote(foo$bar)
    expect_equal(
        fmt('{topic;"} is not a valid module help topic'),
        '"foo$bar" is not a valid module help topic'
    )

    expect_equal(
        fmt('Displaying documentation requires {"roxygen2";\'} installed'),
        'Displaying documentation requires \'roxygen2\' installed'
    )

    mod_name = 'foo'
    expect_equal(
        fmt('No documentation available for {mod_name;"}'),
        'No documentation available for "foo"'
    )

    subject = 'bar'
    expect_equal(
        fmt('No documentation available for {subject;"} in module {mod_name;"}'),
        'No documentation available for "bar" in module "foo"'
    )

    # info.r

    mod_name = 'foo/bar'
    base_paths = c('foo', 'bar', 'baz')
    expect_equal(
        fmt(
            'Unable to load module {mod_name;"}; ',
            'not found in {base_paths;"}'
        ),
        'Unable to load module "foo/bar"; not found in "foo", "bar", "baz"',
    )

    # use.r

    missing = 'foo'
    expect_equal(
        fmt(
            'Name{s} {missing;"} not exported by {mod_name;"}',
            s = if (length(missing) > 1L) 's' else ''
        ),
        'Name "foo" not exported by "foo/bar"',
    )

    missing = c('foo', 'bar')
    expect_equal(
        fmt(
            'Name{s} {missing;"} not exported by {mod_name;"}',
            s = if (length(missing) > 1L) 's' else ''
        ),
        'Names "foo", "bar" not exported by "foo/bar"'
    )
})

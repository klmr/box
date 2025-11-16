context('get exports')

test_that('returns all functions of a whole package attached', {
    results = get_exports(stringr)

    expected_output = getNamespaceExports('stringr')

    expect_contains(results[['stringr']], expected_output)
})

test_that('returns all functions of a whole packaged attached and aliased', {
    results = get_exports(alias = stringr)

    expected_output = getNamespaceExports('stringr')

    expect_named(results, c('alias'))
    expect_contains(results[['alias']], expected_output)
})

test_that('return all functions of a package attached by three dots', {
    results = get_exports(stringr[...])
    expected_output = getNamespaceExports('stringr')

    expect_contains(unname(results), expected_output)
})

test_that('returns attached functions from packages', {
    results = get_exports(stringr[str_pad, str_trim])
    expected_output = c('str_pad', 'str_trim')
    names(expected_output) = c('str_pad', 'str_trim')
    expect_named(results, names(expected_output))
    expect_setequal(unname(results), unname(expected_output))
})

test_that('returns aliased attached functions from packages', {
    results = get_exports(stringr[alias_1 = str_pad, alias_2 = str_trim])
    expected_output = c('str_pad', 'str_trim')
    names(expected_output) = c('alias_1', 'alias_2')
    expect_named(results, names(expected_output))
    expect_setequal(unname(results), unname(expected_output))
})

test_that('throws an error on unknown function attached from package', {
    expect_error(get_exports(stringr[unknown_function]))
})

test_that('returns all functions of a whole module attached', {
    results = get_exports(mod/a)

    expected_output = c(
        'double',
        'modname',
        'get_modname',
        'get_modname2',
        'get_counter',
        'inc',
        '%or%',
        '+.string',
        'which',
        'encoding_test',
        '.hidden',
        '%.%',
        '%x.%',
        '%.x%',
        '%x.x%',
        '%foo.bar',
        '%%.%%',
        '%a%.class%'
    )

    expect_setequal(results[['a']], expected_output)
})

test_that('returns all functions of a whole module attached', {
    results = get_exports(alias = mod/a)

    expected_output = c(
        'double',
        'modname',
        'get_modname',
        'get_modname2',
        'get_counter',
        'inc',
        '%or%',
        '+.string',
        'which',
        'encoding_test',
        '.hidden',
        '%.%',
        '%x.%',
        '%.x%',
        '%x.x%',
        '%foo.bar',
        '%%.%%',
        '%a%.class%'
    )

    expect_named(results, c('alias'))
    expect_setequal(results[['alias']], expected_output)
})

test_that('return all functions of a module attached by three dots', {
    results = get_exports(mod/a[...])
    expected_output = c(
        'double',
        'modname',
        'get_modname',
        'get_modname2',
        'get_counter',
        'inc',
        '%or%',
        '+.string',
        'which',
        'encoding_test',
        '.hidden',
        '%.%',
        '%x.%',
        '%.x%',
        '%x.x%',
        '%foo.bar',
        '%%.%%',
        '%a%.class%'
    )

    expect_contains(unname(results), expected_output)
})

test_that('returns attached functions from modules', {
  results = get_exports(mod/a[get_modname, `%or%`])
  expected_output = c('get_modname', '%or%')
  names(expected_output) = c('get_modname', '%or%')
  expect_named(results, names(expected_output))
  expect_setequal(unname(results), unname(expected_output))
})

test_that('returns attached aliased functions from modules', {
  results = get_exports(mod/a[alias_1 = get_modname, alias_2 = `%or%`])
  expected_output = c('get_modname', '%or%')
  names(expected_output) = c('alias_1', 'alias_2')
  expect_named(results, names(expected_output))
  expect_setequal(unname(results), unname(expected_output))
})

test_that('throws an error on unknown function attached from module', {
  expect_error(get_exports(mod/a[unknown_function]))
})

context('help')

help_test_cases = c(quote(a), quote(a$b), quote(a$b$c), quote(a$b$c$d))
help_test_env = new.env()

local({
    box::use(mod/help/a)
}, envir = help_test_env)

test_that('help topic targets are correctly resolved', {
    # Necessary to allow ‘knitr’ tests to unload ‘knitr’, which in turn requires
    # ‘roxygen2’.
    on.exit(unloadNamespace('roxygen2'))
    a = help_test_env$a
    expected_mods = c(a, a, a$b, a$b$c)
    expected_names = c('.__module__.', 'b', 'c', 'd')
    actual_targets = box:::map(box:::help_topic_target, help_test_cases, list(help_test_env))
    box:::map(expect_identical, box:::map(`[[`, actual_targets, list(1L)), expected_mods)
    box:::map(expect_identical, box:::map(`[[`, actual_targets, list(2L)), expected_names)
})

test_that('documentation can be parsed', {
    # Necessary to allow ‘knitr’ tests to unload ‘knitr’, which in turn requires
    # ‘roxygen2’.
    on.exit(unloadNamespace('roxygen2'))
    a = help_test_env$a
    doc = parse_documentation(attr(a, 'info'), attr(a, 'namespace'))
    expect_length(doc, 1L)
    expect_equal(names(doc), '.__module__.')

    c = a$b$c
    doc = parse_documentation(attr(c, 'info'), attr(c, 'namespace'))
    expect_length(doc, 2L)
    expect_equal(names(doc), c('.__module__.', 'd'))
})

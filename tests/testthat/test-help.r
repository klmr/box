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
    expect_length(doc, 2L)
    expect_named(doc, c('.__module__.', 'alias2'))

    c = a$b$c
    doc = parse_documentation(attr(c, 'info'), attr(c, 'namespace'))
    expect_length(doc, 4L)
    expect_named(doc, c('.__module__.', 'd', 'e', 'f'))
})

test_that('documentation of nested, attached, reexported objects is found', {
    # Necessary to allow ‘knitr’ tests to unload ‘knitr’, which in turn requires
    # ‘roxygen2’.
    on.exit(unloadNamespace('roxygen2'))

    a = help_test_env$a

    a_target = box:::help_topic_target(quote(a), environment())
    expect_identical(a_target, list(a, '.__module__.', 'a'))

    ab_target = box:::help_topic_target(quote(a$b), environment())
    expect_identical(ab_target, list(a$b, '.__module__', 'b'))

    ad_target = box:::help_topic_target(quote(a$alias), environment())
    expect_identical(ad_target, list(a$b$c, 'd', 'alias'))

    ae_target = box:::help_topic_target(quote(a$alias1), environment())
    expect_identical(ae_target, list(a$b$c, 'e', 'alias1'))

    af_target = box:::help_topic_target(quote(a$alias2), environment())
    expect_identical(af_target, list(a, 'alias2', 'alias2'))
})

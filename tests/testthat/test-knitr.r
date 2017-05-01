context('Test that modules works with knitr')

test_that('modules are found when knitr is not loaded', {
    # Ensure knitr isn’t loaded
    unloadNamespace('knitr')
    expect_that(script_path(), equals(getwd()))
})

test_that('modules are found when knitr is loaded', {
    loadNamespace('knitr')
    on.exit(unloadNamespace('knitr'))
    expect_that(script_path(), equals(getwd()))
})

test_that('modules are found inside a knitr document', {
    on.exit(unloadNamespace('knitr'))

    input = 'support/knitr/doc.rmd'
    # Ensure that a different working directory is used.
    knitr::opts_knit$set(root.dir = getwd())
    output = knitr::knit(input, quiet = TRUE)
    on.exit(unlink(output), add = TRUE)

    expected = '```\n## knitr/a\n```'
    expect_match(paste(readLines(output), collapse = '\n'), expected)
})

context('Test that modules works with knitr')

test_that('modules are found when knitr is not loaded', {
    # Ensure knitr isn’t loaded
    unloadNamespace('knitr')
    expect_that(script_path(), equals(getwd()))
})

test_that('modules are found when knitr is loaded', {
    loadNamespace('knitr')
    expect_that(script_path(), equals(getwd()))
})

test_that('modules are found inside a knitr document', {
    input = 'support/knitr/doc.rmd'
    expect_message({
        output = knitr::knit(input, quiet = TRUE)
        unlink(output)
    }, 'knitr/a')
})

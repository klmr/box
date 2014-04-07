# Set up local module environment to test against.
# Note that we override the normal path here.

options(import.path = 'modules',
        import.attach = FALSE)

#' Opposite of \code{is_identical_to}
is_not_identical_to = function (expected, label = NULL) {
    label = if (is.null(label)) testthat:::find_expr('expected') else
            if (! is.character(label) || length(label) != 1) deparse(label) else label

    function (actual)
        expectation(! identical(actual, expected),
                    paste('is identical to', label),
                    paste('is not identical to', label))
}

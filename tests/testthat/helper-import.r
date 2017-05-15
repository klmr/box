# Set up local module environment to test against.
# Note that we override the normal path here.

options(import.path = 'modules',
        import.attach = FALSE)

#' Opposite of \code{is_identical_to}
expect_not_identical = function (object, expected, info = NULL, label = NULL, expected.label = NULL) {
    lab_act = testthat::make_label(object, label)
    lab_exp = testthat::make_label(expected, expected.label)
    ident = identical(object, expected)

    msg = if (ident) 'Objects identical' else ''
    testthat::expect_false(ident, info = info,
                           label = sprintf('%s identical to %s.\n%s',
                                           lab_act, lab_exp, msg))
}

# Set up local module environment to test against.
# Note that we override the normal path here.

options(mod.path = 'modules')

expect_not_identical = function (object, expected, info = NULL, label = NULL, expected.label = NULL) {
    lab_act = testthat::quasi_label(rlang::enquo(object), label)
    lab_exp = testthat::quasi_label(rlang::enquo(expected), expected.label)
    ident = identical(object, expected)

    msg = if (ident) 'Objects identical' else ''
    testthat::expect_false(
        ident, info = info,
        label = sprintf('%s identical to %s.\n%s', lab_act, lab_exp, msg)
    )
}

expect_in = function (name, list) {
    act = testthat::quasi_label(rlang::enquo(list))
    testthat::expect(
        name %in% list,
        sprintf('%s is not in %s.', deparse(name), act$lab)
    )
    invisible(act$val)
}

expect_not_in = function (name, list) {
    act = testthat::quasi_label(rlang::enquo(list))
    testthat::expect(
        ! name %in% list,
        sprintf('%s is in %s.', deparse(name), act$lab)
    )
    invisible(act$val)
}

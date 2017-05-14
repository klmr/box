# Set up local module environment to test against.
# Note that we override the normal path here.

options(import.path = 'modules',
        import.attach = FALSE)

#' Opposite of \code{is_identical_to}
expect_not_identical = function (object, expected, info = NULL, label = NULL, expected.label = NULL) {
    lab_act = make_label(object, label)
    lab_exp = make_label(expected, expected.label)
    ident = identical(object, expected)

    msg = if (ident) 'Objects identical' else ''
    expect(! ident, sprintf('%s identical to %s.\n%s', lab_act, lab_exp, msg),
           info = info)
}

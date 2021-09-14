# Set up local module environment to test against.
# Note that we override the normal path here.

options(box.path = getwd())

expect_not_equal = function (object, expected, info = NULL, label = NULL, expected.label = NULL) {
    act = testthat::quasi_label(rlang::enquo(object), label, arg = 'object')
    exp = testthat::quasi_label(rlang::enquo(expected), expected.label, arg = 'expected')
    cmp = testthat::compare(act$val, exp$val)
    val = deparse(act$val)

    testthat::expect(
        ! cmp$equal,
        sprintf('%s is equal to %s.\n%s == %s', act$lab, exp$lab, val, val),
        info = info
    )
    invisible(act$value)
}

expect_not_identical = function (object, expected, info = NULL, label = NULL, expected.label = NULL) {
    act = testthat::quasi_label(rlang::enquo(object), label, arg = 'object')
    exp = testthat::quasi_label(rlang::enquo(expected), expected.label, arg = 'expected')
    ident = identical(act$val, exp$val)

    testthat::expect(
        ! ident,
        sprintf('%s identical to %s', act$lab, exp$lab),
        info = info,
    )
    invisible(act$val)
}

expect_in = function (object, list) {
    act = testthat::quasi_label(rlang::enquo(list), arg = 'list')
    testthat::expect(
        object %in% act$val,
        sprintf('%s is not in %s.', deparse(object), act$lab)
    )
    invisible(act$val)
}

expect_not_in = function (object, list) {
    act = testthat::quasi_label(rlang::enquo(list), arg = 'list')
    testthat::expect(
        ! object %in% act$val,
        sprintf('%s is in %s.', deparse(object), act$lab)
    )
    invisible(act$val)
}

expect_not_null = function (object, info = NULL, label = NULL) {
    act = testthat::quasi_label(rlang::enquo(object), label, arg = 'object')
    testthat::expect_false(is.null(object), info = info, label = act$lab)
}

expect_box_error = function (object, regexp = NULL, class = NULL, ..., info = NULL, label = NULL) {
    expect_error(
        object = object,
        regexp = regexp,
        class = c(class, 'box_error'),
        ...,
        info = info,
        label = label
    )
}

expect_messages = function (object, has = NULL, has_not = NULL, info = NULL, label = NULL) {
    self = environment()
    messages = character(0L)

    act = withCallingHandlers(
        testthat::quasi_label(rlang::enquo(object), label, arg = 'object'),
        message = function (m) {
            self$messages = c(self$messages, m$message)
            invokeRestart('muffleMessage')
        }
    )

    pretty_messages = paste('*', messages, collapse = '')

    find = function (pattern, x) any(grepl(pattern, x))

    testthat::expect(
        all(vapply(has, find, logical(1L), messages)),
        sprintf(
            '%s did not produce the expected message(s). It produced:\n%s',
            act$lab, pretty_messages
        ),
        info = info
    )

    testthat::expect(
        ! any(vapply(has_not, find, logical(1L), messages)),
        sprintf(
            '%s produces unexpected message(s). It produced:\n%s',
            act$lab, pretty_messages
        ),
        info = info
    )
}

in_globalenv = function (expr) {
    old_ls = ls(.GlobalEnv, all.names = TRUE)
    on.exit({
        new_ls = ls(.GlobalEnv, all.names = TRUE)
        to_delete = setdiff(new_ls, old_ls)
        rm(list = to_delete, envir = .GlobalEnv)
    })
    eval.parent(substitute(eval(quote(expr), .GlobalEnv)))
}

in_source_repo = local({
    in_tests = grepl('tests/testthat$', getwd())
    basedir = if (in_tests) file.path(getwd(), '../..') else getwd()
    file.exists(file.path(basedir, 'DESCRIPTION'))
})

skip_outside_source_repos = function () {
    skip_if(! in_source_repo, 'Outside source code repository')
}

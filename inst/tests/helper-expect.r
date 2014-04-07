expect = function (condition, info = NULL, label = NULL) {
    stopifnot(length(info) <= 1, length(label) <= 1)

    condition = substitute(condition)

    if (is.null(label))
        label = capture.output(print(condition))

    wrap = function (result, error)
        structure(list(passed = isTRUE(result),
                       error = error,
                       failure_msg = 'failed',
                       success_msg = 'succeeded'), class = 'expectation')

    results = tryCatch(eval(condition, envir = parent.frame()),
                       error = function (e) wrap(e, TRUE),
                       warning = function (e) wrap(e, FALSE))

    if (! is(results, 'expectation'))
        results = wrap(results, FALSE)

    results$failure_msg = paste(label, results$failure_msg)
    results$success_msg = paste(label, results$success_msg)

    if (! is.null(info)) {
        results$failure_msg = paste(results$failure_msg, info, sep = '\n')
        results$success_msg = paste(results$success_msg, info, sep = '\n')
    }
    get_reporter()$add_result(results)
    invisible(results)
}

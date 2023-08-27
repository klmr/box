test_use = function (...) {
    call = match.call()
    parse_spec(call[[2L]], names(call)[[2L]] %||% '')
}

expect_identical_spec = function (object, expected) {
    act = quasi_label(rlang::enquo(object), NULL, arg = 'object')
    exp = quasi_label(rlang::enquo(expected), NULL, arg = 'expected')

    ident = identical(act$val, exp$val)
    msg = if (ident) {
        ''
    } else {
        act_str = capture.output(str(unclass(act$val)))
        exp_str = capture.output(str(unclass(exp$val)))
        paste0(paste('  ', act_str, collapse = '\n'), '\n≠\n', paste('  ', exp_str, collapse = '\n'))
    }

    expect(
        ident,
        sprintf('%s not identical to %s:\n%s', act$lab, exp$lab, msg),
        info = NULL
    )
    invisible(act$val)
}

is_mod_spec = function (x) {
    inherits(x, 'box$mod_spec')
}

is_pkg_spec = function (x) {
    inherits(x, 'box$pkg_spec')
}

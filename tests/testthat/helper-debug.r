clear_mods = function () {
    rm(list = names(box:::loaded_mods), envir = box:::loaded_mods)
}

.setup_fun = NULL
.teardown_fun = NULL

context = function (desc) {
    assign('.setup_fun', NULL, envir = parent.env(environment()))
    assign('teardown_funs', NULL, envir = parent.env(environment()))
    testthat::context(desc)
}

test_setup = function (code, env = parent.frame()) {
    assign(
        '.setup_fun',
        rlang::new_function(list(), rlang::enexpr(code), env = env),
        envir = parent.env(environment())
    )
}

test_teardown = function (code, env = parent.frame()) {
    assign(
        '.teardown_fun',
        rlang::new_function(list(), rlang::enexpr(code), env = env),
        envir = parent.env(environment())
    )
}

run_setup = function () {
    if (! is.null(.setup_fun)) {
        # Note that bquote(.(f)()) does NOT perform substitution for whatever
        # reason.
        eval.parent(substitute(f(), list(f = .setup_fun)))
    }
}

run_teardown = function () {
    if (! is.null(.teardown_fun)) {
        # Note that bquote(.(f)()) does NOT perform substitution for whatever
        # reason.
        eval.parent(substitute(f(), list(f = .teardown_fun)))
    }
}

test_that = function (desc, code) {
    eval.parent(bquote({
        run_setup()
        on.exit(run_teardown())
        testthat::test_that(.(desc), .(substitute(code)))
    }))
}

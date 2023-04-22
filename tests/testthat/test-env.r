context(' environments')

test_that('`topenv` works inside modules', {
    box::use(mod/env)

    expected = attr(env, 'namespace')

    expect_identical(env$e1, expected)
    expect_identical(env$e2(), expected)
    expect_identical(env$e3(), expected)
    expect_identical(env$e4()(), expected)
})

test_that('`topenv` works on module environments', {
    box::use(mod/env)
    env_ns = attr(env, 'namespace')
    expect_identical(box::topenv(env), env_ns)

    box::use(stats)
    stats_ns = asNamespace('stats')
    expect_identical(box::topenv(stats), stats_ns)
})

test_that('`topenv` works on module namespaces', {
    box::use(mod/env)
    env_ns = attr(env, 'namespace')
    expect_identical(box::topenv(env_ns), env_ns)

    box::use(stats)
    stats_ns = asNamespace('stats')
    expect_identical(box::topenv(stats_ns), stats_ns)
})

test_that('`topenv` works on non-module environments', {
    expect_identical(in_globalenv(box::topenv()), .GlobalEnv)

    e = new.env(parent = .GlobalEnv)
    expect_identical(local(box::topenv(), envir = e), .GlobalEnv)

    stats_env = as.environment('package:stats')
    expect_identical(box::topenv(stats_env), stats_env)
})

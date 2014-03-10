context('Basic import test')

test_that('module can be imported', {
    a = import(a)
    expect_true(is_module_loaded(module_path(a)))
    expect_true('double' %in% ls(a))
})

test_that('module is uniquely identified by path', {
    a = import(a)
    ba = import(b.a)
    expect_true(is_module_loaded(module_path(a)))
    expect_true(is_module_loaded(module_path(ba)))
    expect_that(module_path(a), is_not_identical_to(module_path(ba)))
    expect_true('double' %in% ls(a))
    expect_false('double' %in% ls(ba))
})

test_that('can use imported function', {
    a = import(a)
    expect_that(a$double(42), equals(42 * 2))
})

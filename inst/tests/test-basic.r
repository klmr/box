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

test_that('modules only export functions', {
    a = import(a)
    expect(length(lsf.str(a)) > 0)
    expect_that(length(lsf.str(a)), equals(length(ls(a))))
    a_namespace = environment(a$double)
    non_functions = setdiff(ls(a_namespace), ls(a))
    expect(length(non_functions) > 0)
    expect_true(exists(non_functions[[1]], envir = a_namespace))
    expect_false(exists(non_functions[[1]], envir = a_namespace,
                        mode = 'function'))
})

test_that('module can modify its variables', {
    a = import(a)
    counter = a$get_counter()
    a$inc()
    expect_that(a$get_counter(), equals(counter + 1))
})

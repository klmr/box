context('Module names')

test_that('the global namespace has no module name', {
    expect(is.null(module_name()))
})

test_that('modules have a name', {
    a = import(a)
    expect(module_name(a) == 'a')
    expect(a$modname == 'a')
})

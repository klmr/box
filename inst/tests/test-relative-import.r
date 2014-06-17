context('Relative imports test')

setup = function () {
    thispath = file.path(getwd(), 'modules/nested')
    prev = getOption('import.path')
    if (! identical(prev, thispath))
        previous_import_path <<- prev
    options(import.path = thispath)
}

teardown = function () {
    options(import.path = previous_import_path)
}

test_that('Imports are absolute by default', {
    on.exit(teardown())
    setup()
    ra = import('relative_a')
    expect_that(ra$a_which(), equals('/a'))
})

test_that('Relative import are always local', {
    on.exit(teardown())
    setup()
    ra = import('relative_a')
    expect_that(ra$local_a_which(), equals('nested/a'))
})

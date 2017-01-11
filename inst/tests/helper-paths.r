realpath = function (path) {
    if (.Platform$OS.type == 'unix')
        system(paste('realpath -m -s', shQuote(path.expand(path))), intern = TRUE)
    else
        normalizePath(path, mustWork = FALSE)
}

expect_paths_equal = function (actual, expected) {
    actual_norm = realpath(merge_path(actual))
    expected_norm = realpath(expected)
    expect_equal(actual_norm, expected_norm, label = deparse(substitute(actual)))
}

expect_is_cwd = function (actual)
    eval.parent(bquote(expect_paths_equal(.(actual), '.')))

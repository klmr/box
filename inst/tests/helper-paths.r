#' Compute normalized logical paths
#'
#' \code{realpath(path)} will return the normalized logical path for
#' \code{path}, similar to \code{normalizePath} but working correctly for
#' nonexistent paths on Unix systems.
#' @param path a character vector of paths
#' @note This function doesn’t work with paths containing newlines; this is a
#' restriction of R because it truncates nul characters and thus cannot pass
#' the \code{-z} flag to the \code{realpath} shell function.
realpath = function (path) {
    if (.Platform$OS.type == 'unix') {
        path_args = paste(shQuote(path.expand(path)), collapse = ' ')
        system(paste('realpath -m -s', path_args), intern = TRUE)
    } else {
        normalizePath(path, mustWork = FALSE)
    }
}

expect_paths_equal = function (actual, expected) {
    actual_norm = realpath(merge_path(actual))
    expected_norm = realpath(expected)
    expect_equal(actual_norm, expected_norm,
                 label = deparse(substitute(actual)),
                 expected.label = deparse(substitute(expected)))
}

expect_is_cwd = function (actual)
    eval.parent(bquote(expect_paths_equal(.(actual), '.')))

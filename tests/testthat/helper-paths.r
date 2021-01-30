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
        normalize_path(path)
    } else {
        sub('\\\\$', '', normalizePath(path, mustWork = FALSE))
    }
}

#' Replacement for \code{normalizePath} that works with non-existent paths on
#' Unix
#'
#' @param path vector of paths to normalize.
#' @details
#' \code{normalize_path} works like \code{\link[base]{normalizePath}}, but also
#' works on non-existent paths. \code{\link[base]{normalizePath}} has an option
#' \code{mustWork = FALSE} for this; however, that option only works on Windows.
#' On Unix systems, it causes paths to be left untouched. However, and as a
#' consequence, \code{normalize_path} does \emph{not} resolve symlinks.
normalize_path = function (path) {
    path = path.expand(path)

    # Make absolute.
    relative_paths = grep('^/', path, invert = TRUE)
    path[relative_paths] = file.path(getwd(), path[relative_paths])

    # In the following, we have to be careful not to remove `.` or `..` when
    # they are part of a path component name, e.g. `.bashrc`.

    path = gsub('(?<=/)\\.(/|$)', '', path, perl = TRUE)

    # The following needs to be in a loop rather than a global search to
    # correctly handle subsequent occurrences of `..`, e.g. `foo/../..`.
    while (any(grepl('/\\.{2}(/|$)', path))) {
        # Remove a single `..`
        path = sub('/([^/]|\\\\/)+/\\.{2}(/|$)', '/', path)
    }

    # Collapse slashes
    path = gsub('//+', '/', path)

    # Remove trailing slashes
    sub('(.+)/$', '\\1', path)
}

expect_paths_equal = function (actual, expected) {
    actual_norm = realpath(box:::merge_path(actual))
    expected_norm = realpath(expected)
    testthat::expect_equal(
        actual_norm, expected_norm,
        label = deparse(substitute(actual)),
        expected.label = deparse(substitute(expected))
    )
}

expect_correct_path_split = function (actual) {
    expect_paths_equal(box:::split_path(actual), actual)
}

expect_is_cwd = function (actual) {
    eval.parent(bquote(expect_paths_equal(.(actual), '.')))
}

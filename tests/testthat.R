# Needed for subshells openend in tests, and does no harm otherwise.
# See <https://github.com/hadley/testthat/issues/144> for details.
Sys.setenv(R_TESTS = '')
testthat::test_check('box')

context("get exports")

test_that("returns all functions of a whole package attached", {
  results = get_module_exports(stringr)

  expected_output = getNamespaceExports("stringr")

  expect_contains(results[[1]][["stringr"]], expected_output)
})

test_that("returns all functions of a whole packaged attached and aliased", {
  results = get_module_exports(alias = stringr)

  expected_output = getNamespaceExports("stringr")

  expect_named(results[[1]], c("alias"))
  expect_contains(results[[1]][["alias"]], expected_output)
})

test_that("return all functions of a package attached by three dots", {
  results = get_module_exports(stringr[...])
  expected_output = getNamespaceExports("stringr")

  expect_contains(unname(results[[1]]), expected_output)
})

test_that("returns attached functions from packages", {
  results = get_module_exports(stringr[str_pad, str_trim])
  expected_output = c("str_pad", "str_trim")
  names(expected_output) = c("str_pad", "str_trim")
  expect_named(results[[1]], names(expected_output))
  expect_setequal(unname(results[[1]]), unname(expected_output))
})

test_that("returns aliased attached functions from packages", {
  results = get_module_exports(stringr[alias_1 = str_pad, alias_2 = str_trim])
  expected_output = c("str_pad", "str_trim")
  names(expected_output) = c("alias_1", "alias_2")
  expect_named(results[[1]], names(expected_output))
  expect_setequal(unname(results[[1]]), unname(expected_output))
})

test_that("throws an error on unknown function attached", {
  expect_error(get_module_exports(stringr[unknown_function]))
})

#' Double a number
#'
#' Add a number to itself by the cunning use of arithmetic.
#'
#' @param x a number
#' @return \code{x * 2}
double = function (x) x * 2

.modname = module_name()

#' Counter for testing
counter = 1

#' The module’s name
get_modname = function () .modname

#' The module’s name, via a function
get_modname2 = function () module_name()

#' Read the counter
get_counter = function () counter

#' Increment the counter
inc = function ()
    counter <<- counter + 1

#' Use \code{a} if it exists, else \code{b}
`%or%` = function (a, b)
    if (length(a) > 0) a else b

#' String concatenation
`+.string` = function (a, b)
    paste(a, b, sep = '')

which = function () '/a'

encoding_test = function () '☃' # U+2603: SNOWMAN

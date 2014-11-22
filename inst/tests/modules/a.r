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
#' @name get_modname
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

# Test cases for the issue 42. The semantics of the functions don’t matter so I
# am using whimsical place-holders. What matters is whether or not the functions
# get exported as operators.

`%.%` = function (f, g) function (x) f(g(x))

`%x.%` = function (x, f) f(x)

`%.x%` = function (f, x) f(x)

`%x.x%` = function (x, y) function (f) f(x, y)

`%foo.bar` = function (x) message(x)

`%%.%%` = function (a, b) list(a, b)

`%a%.class%` = function (a, b) list(a, b)

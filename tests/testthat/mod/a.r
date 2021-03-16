#' A test module
#'
#' With a description
'.__module__.'

#' Double a number
#'
#' Add a number to itself by the cunning use of arithmetic.
#'
#' @param x a number
#' @return \code{x * 2}
#' @export
double = function (x) x * 2

#' @export
modname = box::name()

private_modname = box::name()

# Variables at namespace scope are locked so mutable variables need to be
# wrapped inside a closure.
make_counter = function () {
    counter = 1L

    list(
        get = function () counter,
        inc = function () counter <<- counter + 1L
    )
}

counter = make_counter()

#' The module’s name
#' @export
get_modname = function () private_modname

#' The module’s name, via a function
#' @name get_modname
#' @export
get_modname2 = function () box::name()

#' Read the counter
#' @export
get_counter = counter$get

#' Increment the counter
#' @export
inc = counter$inc

#' Use \code{a} if it exists, else \code{b}
#' @export
`%or%` = function (a, b)
    if (length(a) > 0L) a else b

#' String concatenation
#' @export
`+.string` = function (a, b)
    paste(a, b, sep = '')

#' @export
which = function () '/a'

#' @export
encoding_test = function () '☃' # U+2603: SNOWMAN

#' @export
.hidden = 1L

# Test cases for the issue 42. The semantics of the functions don’t matter so I
# am using whimsical place-holders. What matters is whether or not the functions
# get exported as operators.

#' @export
`%.%` = function (f, g) function (x) f(g(x))

#' @export
`%x.%` = function (x, f) f(x)

#' @export
`%.x%` = function (f, x) f(x)

#' @export
`%x.x%` = function (x, y) function (f) f(x, y)

#' @export
`%foo.bar` = function (x) message(x)

#' @export
`%%.%%` = function (a, b) list(a, b)

#' @export
`%a%.class%` = function (a, b) list(a, b)

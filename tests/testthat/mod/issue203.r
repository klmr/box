# The following defines a function which has a function inside its body. This is
# *different* from a nested function; that is, `f` is different from
#
#   f1 = function () { identity }
#
# … because `f1` contains a *name* in its body. Likewise, it is different from
#
#   f2 = function () { function (x) x }
#
# … because `f2` contains a *call expression* which, when executed, *defines* a
# function, in its body. That is:
#
#   class(body(f)[[2L]])  == 'function'
#   class(body(f1)[[2L]]) == 'name'
#   class(body(f2)[[2L]]) == 'call'
f = function () { NULL }
body(f)[[2L]] = identity

#' `g` clearly isn’t a generic even though `UseMethod` is used inside a nested
#' function in its body.
#' @export
g = function (x) {
    nested = function () UseMethod('nested')
    nested()
}

#' … nor is `h`.
#' @export
h = function () { NULL }
body(h)[[2L]] = function () UseMethod('foo')

# The following defines a function which has a function inside its body. This is
# *different* from a nested function; that is, `f` is different from
#
#   g = function () { identity }
#
# … because `g` contains a *name* in its body. Likewise, it is different from
#
#   h = function () { function (x) x }
#
# … because `h` contains a *call expression* in its body. That is:
#
#   class(body(f)[[2L]]) == 'function'
#   class(body(g)[[2L]]) == 'name'
#   class(body(h)[[2L]]) == 'call'
f = function () { NULL }

body(f)[[2L]] = identity

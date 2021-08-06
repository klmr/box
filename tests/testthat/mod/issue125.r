f = function () NULL
body(f) = substitute(
    do.call(g, list()),
    list(g = function () 1)
)

box::export()

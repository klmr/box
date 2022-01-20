#' @export
a = 'reexport$a'

box::use(./reexport_sub[a, b, c, d])

b = 'reexport$b'

#' @export
c = 'reexport$c'

#' @export
box::use(
    sub = ./reexport_sub[d = c, e = b]
    , # Keep trailing comma to test regression of fix for #263.
)

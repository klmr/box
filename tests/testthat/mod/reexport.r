# Note: the order of the definitions/exports in the following is intentional,
# and relied on in the corresponding tests.

#' @export
a = 'reexport$a'

mod::use(./reexport_sub[a, b, c, d])

b = 'reexport$b'

#' @export
c = 'reexport$c'

#' @export
mod::use(sub = ./reexport_sub[a = c, b])

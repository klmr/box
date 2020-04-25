#' @export
a = 'reexport$a'

xyz::use(./reexport_sub[a, b, c, d])

b = 'reexport$b'

#' @export
c = 'reexport$c'

#' @export
xyz::use(sub = ./reexport_sub[d = c, e = b])

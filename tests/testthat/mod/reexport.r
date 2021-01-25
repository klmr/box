#' @export
a = 'reexport$a'

pod::use(./reexport_sub[a, b, c, d])

b = 'reexport$b'

#' @export
c = 'reexport$c'

#' @export
pod::use(sub = ./reexport_sub[d = c, e = b])

mod::use(a = ./circular_a)

#' @export
x = a$getx()

#' @export
getx = function () x

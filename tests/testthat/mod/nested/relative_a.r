box::use(mod/a)

# Muffle message
silently = function (expr) {
    on.exit({sink(); close(file)})
    file = textConnection('out', 'w', local = TRUE)
    sink(file)
    expr
}

silently(box::use(local_a = ./a))

#' @export
a_which = function () a$which()

#' @export
local_a_which = function () local_a$which()

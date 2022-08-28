f = function() {
    box::use(./a[...])
    helper()
}

g = function() {
    box::use(./a)
    helper()
}

h = function() {
    box::use(./a[`%.%`])
    helper()
}

ns = environment()

#' @export
helper_var = 0L

helper = function() { ns$helper_var = helper_var + 1L }

f()
g()
h()

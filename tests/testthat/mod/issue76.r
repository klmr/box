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

#' @export
helper_var = 0L

helper = function() { helper_var <<- helper_var + 1L }

f()
g()
h()

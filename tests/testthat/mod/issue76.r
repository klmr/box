f = function() {
    xyz::use(./a[...])
    helper()
}

g = function() {
    xyz::use(./a)
    helper()
}

h = function() {
    xyz::use(./a[`%.%`])
    helper()
}

#' @export
helper_var = 0L

helper = function() { helper_var <<- helper_var + 1L }

f()
g()
h()

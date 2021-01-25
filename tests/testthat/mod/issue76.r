f = function() {
    pod::use(./a[...])
    helper()
}

g = function() {
    pod::use(./a)
    helper()
}

h = function() {
    pod::use(./a[`%.%`])
    helper()
}

#' @export
helper_var = 0L

helper = function() { helper_var <<- helper_var + 1L }

f()
g()
h()

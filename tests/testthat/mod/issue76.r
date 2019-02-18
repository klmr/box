f = function() {
    mod::use(./a[...])
    helper()
}

g = function() {
    mod::use(./a)
    helper()
}

h = function() {
    mod::use(./a[`%.%`])
    helper()
}

#' @export
helper_var = 0L

helper = function() { helper_var <<- helper_var + 1L }

f()
g()
h()

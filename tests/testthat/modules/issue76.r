f = function() {
    import('a', attach = TRUE)
    helper()
}

g = function() {
    import('a', attach = FALSE, attach_operators = FALSE)
    helper()
}

h = function() {
    import('a', attach = FALSE, attach_operators = TRUE)
    helper()
}

helper_var = 0

helper = function() { helper_var <<- helper_var + 1 }

f()
g()
h()

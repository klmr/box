a = import('a')

# Muffle message
silently = function (expr) {
    on.exit({sink(); close(file)})
    file = textConnection('out', 'w', local = TRUE)
    sink(file)
    expr
}

local_a = silently(import('./a'))

a_which = function () a$which()

local_a_which = function () local_a$which()

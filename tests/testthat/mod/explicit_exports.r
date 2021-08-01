box::use(a = ./a[...])

double = function (x) c(x, x)

hidden = 'hidden'

# module, local name, imported name
#    └──────┐  └──┐       ┌─┘
box::export(a, double, modname)

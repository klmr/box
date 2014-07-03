double = function (x) x * 2

.modname = module_name()

counter = 1

get_modname = function () .modname

get_modname2 = function () module_name()

get_counter = function () counter

inc = function ()
    counter <<- counter + 1

`%or%` = function (a, b)
    if (length(a) > 0) a else b

`+.string` = function (a, b)
    paste(a, b, sep = '')

which = function () '/a'

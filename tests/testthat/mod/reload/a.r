box::use(./b)

.on_unload = function (ns) {
    message('a unloaded')
}

box::export()

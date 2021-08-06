.on_load = function (ns) {
    message('c loaded')
}

.on_unload = function (ns) {
    message('c unloaded')
}

box::export()

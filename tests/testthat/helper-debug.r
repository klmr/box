clear_mods = function () {
    rm(list = names(mod:::loaded_mods), envir = mod:::loaded_mods)
}

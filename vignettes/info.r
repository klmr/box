.on_load = function (ns) {
    message('Loading module "', xyz::name(), '"')
    message('Module path: "', basename(xyz::file()), '"')
}

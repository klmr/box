.on_load = function (ns) {
    message(
        'Loading module "', xyz::name(), '"\n',
        'Module path: "', basename(xyz::file()), '"'
    )
}

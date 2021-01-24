.on_load = function (ns) {
    message(
        'Loading module "', box::name(), '"\n',
        'Module path: "', basename(box::file()), '"'
    )
}

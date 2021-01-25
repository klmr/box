.on_load = function (ns) {
    message(
        'Loading module "', pod::name(), '"\n',
        'Module path: "', basename(pod::file()), '"'
    )
}

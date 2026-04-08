.on_load = function (ns) {
    makeActiveBinding(
        'binding',
        function () {
            message('get')
            1L
        },
        ns
    )
}

box::export(binding)

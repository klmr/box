a = 1
b = 'foo'
.c = 'hidden'

message('legacy module loaded')

.on_load = function (ns) {
    message('.on_load is not called')
}

test = function (x)
    UseMethod('test')

test.default = function (x)
    'test.default'

test.character = function (x)
    'test.character'

print.test = function (x)
    's3$print.test'

register_S3_method('print', 'test', print.test)

seq = function (from, to)
    UseMethod('seq')

seq.default = function (from, to)
    's3$seq.default'

seq.int.test = function (from, to)
    seq.int(from, to)

register_S3_method('seq.int', 'test', seq.int.test)

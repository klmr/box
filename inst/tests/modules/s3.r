test = function (x)
    UseMethod('test')

test.default = function (x)
    'test.default'

test.character = function (x)
    'test.character'

print.test = function (x)
    's3$print.test'

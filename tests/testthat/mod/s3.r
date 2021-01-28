#' @export
test = function (x) UseMethod('test')

test.default = function (x) 'test.default'

test.character = function (x) 'test.character'

print.test = function (x) 's3$print.test'

box::register_S3_method('print', 'test', print.test)

#' @export
se = function (...) UseMethod('se')

se.default = function (...) 's3$se.default'

se.contrast.test = function (...) 's3$se.contrast.test'

# Adding a method to a generic defined in another package requires importing it.
box::use(stats[se.contrast])

box::register_S3_method('se.contrast', 'test', se.contrast.test)

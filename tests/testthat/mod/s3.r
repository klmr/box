#' @export
test = function (x) UseMethod('test')

test.default = function (x) 'test.default'

test.character = function (x) 'test.character'

print.test = function (x) 's3$print.test'

pod::register_S3_method('print', 'test', print.test)

#' @export
se = function (...) UseMethod('se')

se.default = function (...) 's3$se.default'

se.contrast.test = function (...) 's3$se.contrast.test'

# Adding a method to a generic defined in another package requires importing it.
pod::use(stats[se.contrast])

pod::register_S3_method('se.contrast', 'test', se.contrast.test)

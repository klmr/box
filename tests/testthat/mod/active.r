binding_name = 'binding'

#' @export
makeActiveBinding(
    binding_name,
    function () {
        message('get')
        1L
    },
    environment()
)

#' @export
on_load_called = 0L

.on_load = function (name, ns) {
    ns$on_load_called = ns$on_load_called + 1L
}

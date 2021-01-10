#' @export
on_load_called = 0L

.on_load = function (ns) {
    ns$on_load_called = ns$on_load_called + 1L
}

#' @export
register_unload_callback = local({
    unloaded = NULL

    function (callback) {
        unloaded <<- callback
    }
}, envir = (callback = new.env()))

.on_unload = function (ns) {
    if (! is.null(callback$unloaded)) {
        callback$unloaded()
    }
}

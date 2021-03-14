box::use(testthat[...])

.on_load = function (ns) {
    test_dir(box::file())
}

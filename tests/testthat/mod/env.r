#' @export
e1 = box::topenv()

#' @export
e2 = function () {
    box::topenv()
}

#' @export
e3 = function () {
    e2()
}

#' @export
e4 = function () {
    function () box::topenv()
}

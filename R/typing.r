`%==%` = function (x, y) {
    identical(x, y)
}

`%!=%` = function (x, y) {
    ! identical(x, y)
}

check_dots_unnamed = function (definition = sys.function(sys.parent()), call = sys.call(sys.parent())) {
    dots = match.call(definition = definition, call = call, expand.dots = FALSE)$...
    if (is.null(names(dots))) return()

    throw('unexpected named argument', call)
}

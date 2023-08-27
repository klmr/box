#' A test module
'.__module__.'

#' @export
box::use(./b)

#' @export
box::use(./b/c[alias = d, alias1 = e])

#' Overridden documentation
#'
#' @name alias2
#' @export
box::use(./b/c[alias2 = f])

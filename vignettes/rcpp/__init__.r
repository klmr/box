Rcpp::sourceCpp(mod::file('convolve.cpp'), env = environment())

#' @export
convolve = function (a, b) cpp_convolve(a, b)

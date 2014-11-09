#' @param function_name function name as character string
is_S3_user_generic = function (function_name) {
    is_S3 = function (b) {
        if (length(b) == 0)
            return(FALSE)
        if (is.call(b)) {
            if (b[[1]] == 'UseMethod')
                return(TRUE)
            return(is_S3(as.list(b)[-1]))
        }
        is.recursive(b) && (is_S3(b[[1]]) || is_S3(b[-1]))
    }

    is_S3(body(match.fun(function_name)))
}

# TODO: Ensure we handle ambiguous cases correctly. Consider:
# `print.some.class`, which could be method `print` or `print.some`. Solution:
# simply FORBID function names with dots in them. However, this isn’t always
# possible because we may want to extend existing methods.

make_S3_methods_known = function (module) {
    # Ambiguous cases must be manually registered by the user, and are ignored
    # here, by checking for each method in turn has already been registered.

    # An ambiguous case looks like this: `print.data.frame`.

    # First step: find generics defined in module

    # Second step: register known methods for those generics

    # Third step: register methods for generics defined elsewhere
}

register_S3_method = function (name, class, method) {
    module = environment(method)
    attr(module, 's3') = c(attr(module, 's3'), method)
    registerS3method(name, class, method, module)
}

#' @param function_name function name as character string
is_S3_user_generic = function (function_name, envir = parent.frame()) {
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

    is_S3(body(get(function_name, envir = envir, mode = 'function')))
}

lsf = function (envir) {
    names = ls(envir)
    Filter(function (n) exists(n, envir, mode = 'function', inherits = FALSE),
           names)
}

# TODO: Ensure we handle ambiguous cases correctly. Consider:
# `print.some.class`, which could be method `print` or `print.some`. Solution:
# simply FORBID function names with dots in them. However, this isn’t always
# possible because we may want to extend existing methods.

make_S3_methods_known = function (module) {
    # Ambiguous cases must be manually registered by the user, and are ignored
    # here, by checking for each method in turn that has already been
    # registered.

    # An ambiguous case looks like this: `print.data.frame`.

    # First step: find generics defined in module

    functions = lsf(module)
    generics = functions[vapply(functions, is_S3_user_generic, logical(1),
                                envir = module)]

    # Second step: register known methods for those generics

    find_methods = function (generic)
        grep(sprintf('^%s\\.[^.]', generic), functions, value = TRUE)

    register_method = function (name, generic) {
        # + 1 for dot, + 1 for position after that.
        class = substr(name, nchar(generic) + 2, nchar(name))
        method = get(name, envir = module, mode = 'function')
        registerS3method(generic, class, method, module)
    }

    methods = sapply(generics, find_methods, simplify = FALSE)

    Map(function (name) Map(register_method, methods[[name]], name),
        names(methods))

    # Third step: register methods for generics defined elsewhere

    NULL
}

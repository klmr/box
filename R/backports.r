if (getRversion() < '4.0.0') {
    deparse1 = function (expr, collapse = ' ', width.cutoff = 500L, ...) {
        paste(deparse(expr, width.cutoff, ...), collapse = collapse)
    }

    activeBindingFunction = function (sym, env) {
        class = class(env)
        on.exit({class(env) = class})
        as.list(`class<-`(env, NULL), all.names = TRUE)[[sym]]
    }

    tryInvokeRestart = function (r, ...) {
        if (! isRestart(r)) r = findRestart(r)
        if (! is.null(r)) invokeRestart(r, ...)
    }
}

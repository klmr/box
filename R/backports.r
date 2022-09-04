if (getRversion() < '4.0.0') {
    deparse1 = function (expr, collapse = ' ', width.cutoff = 500L, ...) {
        paste(deparse(expr, width.cutoff, ...), collapse = collapse)
    }

    activeBindingFunction = function (sym, env) {
        as.list(`class<-`(env, NULL), all.names = TRUE)[[sym]]
    }
}

#include "Rinternals.h"

// [BEGIN:includes]
#include "R_ext/Parse.h"
// [END:includes]

// [BEGIN:otherdefs]
/* #define LOG(format, ...) \ */
/*     fprintf(stderr, "[%s] " format, __FUNCTION__, __VA_ARGS__) */

#define LOG(format, ...) do {} while (0)

static SEXP current_frame_fun = NULL;

static void init_frame(void);

static SEXP current_frame(void) {
    LOG("current_frame_fun = %p\n", (void*) current_frame_fun);
    if (! current_frame_fun) init_frame();
    LOG("current_frame_fun = %p\n", (void*) current_frame_fun);
    return Rf_eval(current_frame_fun, R_EmptyEnv);
}

static SEXP new_function(SEXP formals, SEXP body) {
    LOG("formals = %p, body = %p\n", (void*) formals, (void*) body);
    SEXP def_args = PROTECT(Rf_cons(formals, PROTECT(Rf_cons(body, R_NilValue))));
    SEXP def_expr = PROTECT(Rf_lcons(Rf_install("function"), def_args));
    SEXP fun = Rf_eval(def_expr, R_BaseEnv);

    UNPROTECT(3);
    return fun;
}

static void init_frame(void) {
    ParseStatus status;
    SEXP code = PROTECT(Rf_mkString("as.call(list(sys.frame, -1L))"));
    LOG("code = %p\n", code);
    SEXP expr = PROTECT(VECTOR_ELT(PROTECT(R_ParseVector(code, -1, &status, R_NilValue)), 0));
    LOG("expr = %p\n", expr);
    SEXP body = PROTECT(Rf_eval(expr, R_BaseEnv));
    LOG("body = %p\n", body);
    SEXP func = PROTECT(new_function(R_NilValue, body));
    LOG("func = %p\n", func);
    current_frame_fun = PROTECT(Rf_lcons(func, R_NilValue));

    UNPROTECT(5);
}
// [END:otherdefs]

SEXP c_strict_extract(SEXP e1, SEXP e2) {
// [BEGIN:body]
    LOG("e1 = %p, e2 = %p\n", e1, e2);
    PROTECT(e1);
    if (! isEnvironment(e1)) {
        UNPROTECT(1);
        error("first argument was not a module environment");
        return R_NilValue;
    }
    PROTECT(e2);
    LOG("length(e2) = %d\n", LENGTH(e2));
    SEXP name = PROTECT(installTrChar(STRING_ELT(e2, 0)));
    SEXP ret = findVarInFrame(e1, name);
    LOG("ret = %p\n", ret);
    if (ret == R_UnboundValue) {
        SEXP parent = PROTECT(current_frame());
        LOG("parent = %p\n", parent);
        ParseStatus status;
        SEXP call_code = PROTECT(Rf_mkString("sys.call(-1L)"));
        SEXP call_expr = PROTECT(R_ParseVector(call_code, -1, &status, R_NilValue));
        SEXP call = VECTOR_ELT(PROTECT(Rf_eval(call_expr, parent)), 0);
        call = PROTECT(Rf_eval(call, parent));
        SEXP fst_arg = PROTECT(CADR(call));

        errorcall(
            call, "name '%s' not found in '%s'",
            translateChar(STRING_ELT(e2, 0)),
            translateChar(PRINTNAME(fst_arg))
        );
        UNPROTECT(9);
        return R_NilValue;
    }
    UNPROTECT(3);
    return ret;
// [END:body]
}

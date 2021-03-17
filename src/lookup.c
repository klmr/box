#define R_NO_REMAP
#include "Rinternals.h"
#include "R_ext/Parse.h"

static SEXP parent_frame(void);
static SEXP sys_call(SEXP parent);

/**
 * Extract a named value from an environment (called as {@code e1$e2}).
 * @param e1 a module environment or module namespace
 * @param e2 a length-1 character string vector that corresponds to the name.
 *  This is a character string rather than an unevaluated name, since this is
 *  how R dispatches the generic {@code `$`} to a method.
 * @return the value corresponding to the name in the environment, if it exists.
 * Throws an error if {@code e1} is not an environment, or if {@code e2} does
 * not exist.
 */
SEXP strict_extract(SEXP e1, SEXP e2) {
    if (! Rf_isEnvironment(e1)) {
        Rf_error("first argument was not a module environment");
        return R_NilValue;
    }

    SEXP name = PROTECT(Rf_installTrChar(STRING_ELT(e2, 0)));
    SEXP ret = Rf_findVarInFrame(e1, name);

    if (ret == R_UnboundValue) {
        SEXP parent = PROTECT(parent_frame());
        SEXP call = PROTECT(sys_call(parent));
        SEXP fst_arg = PROTECT(CADR(call));

        Rf_errorcall(
            call, "name '%s' not found in '%s'",
            Rf_translateChar(STRING_ELT(e2, 0)),
            Rf_translateChar(PRINTNAME(fst_arg))
        );
        UNPROTECT(4);
        return R_NilValue;
    }

    UNPROTECT(1);
    return ret;
}

// Cached version of an R function that calls `sys.frame(-1L)`.
static SEXP parent_frame_func = NULL;

static void init_parent_frame_func(void);

// Return the calling R frame.
static SEXP parent_frame(void) {
    if (! parent_frame_func) init_parent_frame_func();
    return Rf_eval(parent_frame_func, R_EmptyEnv);
}

// Return the call that describes the R function which invoked the parent
// function that calls this C function, identified by `parent`.
static SEXP sys_call(SEXP parent) {
    ParseStatus status;
    SEXP code = PROTECT(Rf_mkString("sys.call(-1L)"));
    SEXP expr = PROTECT(R_ParseVector(code, -1, &status, R_NilValue));
    SEXP func = VECTOR_ELT(PROTECT(Rf_eval(expr, R_BaseEnv)), 0);
    SEXP call = Rf_eval(func, parent);

    UNPROTECT(3);
    return call;
}

// Create a new R closure from the given formals and body.
static SEXP new_function(SEXP formals, SEXP body) {
    SEXP def_args = PROTECT(Rf_cons(formals, PROTECT(Rf_cons(body, R_NilValue))));
    SEXP def_expr = PROTECT(Rf_lcons(Rf_install("function"), def_args));
    SEXP fun = Rf_eval(def_expr, R_BaseEnv);

    UNPROTECT(3);
    return fun;
}

static void init_parent_frame_func(void) {
    ParseStatus status;
    SEXP code = PROTECT(Rf_mkString("as.call(list(sys.frame, -1L))"));
    SEXP expr = PROTECT(VECTOR_ELT(PROTECT(R_ParseVector(code, -1, &status, R_NilValue)), 0));
    SEXP body = PROTECT(Rf_eval(expr, R_BaseEnv));
    SEXP func = PROTECT(new_function(R_NilValue, body));
    parent_frame_func = Rf_lcons(func, R_NilValue);
    R_PreserveObject(parent_frame_func);
    MARK_NOT_MUTABLE(parent_frame_func);

    UNPROTECT(5);
}

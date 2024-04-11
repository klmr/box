#define R_NO_REMAP
#include "Rinternals.h"
#include "R_ext/Parse.h"
#include "Rversion.h"

#if R_VERSION < R_Version(3, 6, 2)
// Declaration is internal before R 3.6.2.
SEXP Rf_installTrChar(SEXP);
#endif

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
SEXP strict_extract(SEXP call, SEXP op, SEXP args, SEXP rho) {
    args = CDR(args);  /* skip the argument c_strict_extract */
    SEXP e1 = CAR(args); args = CDR(args);
    SEXP e2 = CAR(args); args = CDR(args);
    if (! Rf_isEnvironment(e1)) {
        Rf_error("first argument was not a module environment");
    }
    if (!IS_SCALAR(e2, STRSXP)) {
        Rf_error("second argument was not a character string");
    }

    // Return value of `install` does not need to be protected:
    // <https://github.com/kalibera/cran-checks/blob/master/rchk/PROTECT.md>
    SEXP name = Rf_installTrChar(STRING_ELT(e2, 0));
    SEXP ret = Rf_findVarInFrame(e1, name);

    if (ret == R_UnboundValue) {
        /* renamed to avoid clash with strict_extract argument */
        SEXP call_for_error = PROTECT(sys_call(rho));
        /* fst_arg does not need to be protected since call_for_error is protected */
        SEXP fst_arg = CADR(call_for_error);

        if (TYPEOF(fst_arg) == SYMSXP) {
            Rf_errorcall(
                call_for_error, "name '%s' not found in '%s'",
                Rf_translateChar(STRING_ELT(e2, 0)),
                Rf_translateChar(PRINTNAME(fst_arg))
            );
        }

        // while Rf_getAttrib should not allocate in this case,
        // it is still regarded as an allocating function,
        // so we should protect regardless to make rchk happy
        SEXP name = PROTECT(Rf_getAttrib(e1, Rf_install("name")));
        if (IS_SCALAR(name, STRSXP)) {
            Rf_errorcall(
                call_for_error, "name '%s' not found in '%s'",
                Rf_translateChar(STRING_ELT(e2, 0)),
                Rf_translateChar(STRING_ELT(name, 0))
            );
        }

        // if both previous conditions were false, use the pointer??
        Rf_errorcall(
            call_for_error, "name '%s' not found in '<environment: %p>'",
            Rf_translateChar(STRING_ELT(e2, 0)),
            (void *)e1
        );
    }

    /* if ret is a promise, evaluate it */
    if (TYPEOF(ret) == PROMSXP) {
        if (PRVALUE(ret) == R_UnboundValue) {
            PROTECT(ret);
            ret = Rf_eval(ret, R_EmptyEnv);
            UNPROTECT(1);
        }
        else ret = PRVALUE(ret);
    }
    return ret;
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

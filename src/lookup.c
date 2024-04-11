#define R_NO_REMAP
#include "Rinternals.h"
#include "R_ext/Parse.h"
#include "Rversion.h"

#if R_VERSION < R_Version(3, 6, 2)
// Declaration is internal before R 3.6.2.
SEXP Rf_installTrChar(SEXP);
#endif

static SEXP sys_call(SEXP rho);

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

        // this would only be NULL if the user did .External2(box:::c_strict_extract, e1, e2)
        // unlikely that someone would do that, but they could
        if (call_for_error != R_NilValue) {
            // the previous code which used sys.call(-1) is incorrect.
            // there is no guarantee that the call before `$.box$mod`(utils, adist) is the call utils$adist.
            // it could be different due to inheritance or if the user directly calls `$.box$mod`.
            // so instead, return sys.call() i.e. `$.box$mod`(e1, e2) or `$.box$ns`(e1, e2)
            //
            // that being said, sys.call() prints ugly "Error in `$.box$mod`(utils, adist)"
            // so change the first element to `$` which prints better "Error in utils$adist"
            // idea taken from dispatchMethod in which the generic function name is replaced with the specific method name;
            // this essentially undoes that replacement.

            // duplicate the call if necessary before modifying it
            if (MAYBE_REFERENCED(call_for_error)) {
                call_for_error = PROTECT(Rf_shallow_duplicate(call_for_error));
            }
            SETCAR(call_for_error, R_DollarSymbol);

            /* fst_arg does not need to be protected since call_for_error is protected */
            SEXP fst_arg = CADR(call_for_error);

            if (TYPEOF(fst_arg) == SYMSXP) {
                Rf_errorcall(
                    call_for_error, "name '%s' not found in '%s'",
                    Rf_translateChar(STRING_ELT(e2, 0)),
                    Rf_translateChar(PRINTNAME(fst_arg))
                );
            }
        }
        // use the call to .External2() instead??
        else call_for_error = call;

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

    /* if ret is a promise, evaluate it. see "SEXP do_get" */
    if (TYPEOF(ret) == PROMSXP) {
        PROTECT(ret);
        ret = Rf_eval(ret, R_EmptyEnv);
        UNPROTECT(1);
    }
    void ENSURE_NAMED(SEXP x);
    ENSURE_NAMED(ret);
    return ret;
}

// Return the call that describes the R function which invoked this C function, identified by `rho`.
static SEXP sys_call(SEXP rho) {
    // Rf_lcons protects its arguments, so as long as only one of the arguments allocates, we do not need to protect them.
    // the call we have built here is equivalent to `as.call(list(sys.call))`
    SEXP expr = PROTECT(Rf_lcons(Rf_findVarInFrame(R_BaseEnv, Rf_install("sys.call")), R_NilValue));
    // could alternatively use SEXP expr = PROTECT(Rf_lcons(Rf_eval(Rf_install("sys.call"), R_BaseEnv), R_NilValue));
    SEXP call = Rf_eval(expr, rho);

    UNPROTECT(1);
    return call;
}

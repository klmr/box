#define R_NO_REMAP
#include "Rinternals.h"

#include <stdio.h>

SEXP external_env(SEXP args) {
    SEXP e1 = CADR(args);
    SEXP e2 = CADDR(args);

    // if (! Rf_isEnvironment(e1)) {
    //     Rf_error("first argument was not a module environment");
    // }

    SEXP name = Rf_installTrChar(STRING_ELT(e2, 0));
    SEXP ret = Rf_findVarInFrame(e1, name);

    if (ret == R_UnboundValue) {
        SEXP env = CADDDR(args);
        Rf_error("Nice error message");
    }

    return ret;
}

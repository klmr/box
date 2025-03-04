#define R_NO_REMAP
#include "Rinternals.h"

SEXP strict_extract(SEXP e1, SEXP e2, SEXP rho);
SEXP external_strict_extract(SEXP args);
SEXP unlock_env(SEXP env);

static const R_CallMethodDef callMethods[] = {
    {"c_strict_extract", (DL_FUNC) &strict_extract, 3},
    {"c_unlock_env", (DL_FUNC) &unlock_env, 1},
    {NULL, NULL, 0}
};

static const R_ExternalMethodDef externalMethods[] = {
    // {"c_strict_extract", (DL_FUNC) &external_strict_extract, 3}, // use whichever
    {NULL, NULL, 0}
};

void R_init_box(DllInfo *info) {
    R_registerRoutines(info, NULL, callMethods, NULL, externalMethods);
    R_useDynamicSymbols(info, FALSE);
    R_forceSymbols(info, TRUE);
}

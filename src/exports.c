#include "Rinternals.h"

SEXP c_strict_extract(SEXP e1, SEXP e2);
SEXP c_unlock_env(SEXP env);

static const R_CallMethodDef methods[] = {
    {"c_strict_extract", (DL_FUNC) &c_strict_extract, 2},
    {"c_unlock_env", (DL_FUNC) &c_unlock_env, 1},
    {NULL, NULL, 0}
};

void R_init_lock_env(DllInfo* info) {
    R_registerRoutines(info, NULL, methods, NULL, NULL);
    R_useDynamicSymbols(info, FALSE);
    R_forceSymbols(info, TRUE);
}
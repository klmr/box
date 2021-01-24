#include "Rinternals.h"

// Based on <https://gist.github.com/wch/3280369>

#define FRAME_LOCK_MASK (1<<14)
#define FRAME_IS_LOCKED(e) (ENVFLAGS(e) & FRAME_LOCK_MASK)
#define UNLOCK_FRAME(e) SET_ENVFLAGS(e, ENVFLAGS(e) & (~ FRAME_LOCK_MASK))

SEXP unlock_env(SEXP env) {
    if (TYPEOF(env) != ENVSXP) error("not an environment");
    UNLOCK_FRAME(env);
    return R_NilValue;
}

static const R_CallMethodDef methods[] = {
    {"unlock_env", (DL_FUNC) &unlock_env, 1},
    {NULL, NULL, 0}
};

void R_init_lock_env(DllInfo* info) {
    R_registerRoutines(info, NULL, methods, NULL, NULL);
    R_useDynamicSymbols(info, FALSE);
    R_forceSymbols(info, TRUE);
}

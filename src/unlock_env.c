#include "Rinternals.h"

// Based on <https://gist.github.com/wch/3280369>

#define FRAME_LOCK_MASK (1<<14)
#define FRAME_IS_LOCKED(e) (ENVFLAGS(e) & FRAME_LOCK_MASK)
#define UNLOCK_FRAME(e) SET_ENVFLAGS(e, ENVFLAGS(e) & (~ FRAME_LOCK_MASK))

SEXP c_unlock_env(SEXP env) {
    if (TYPEOF(env) != ENVSXP) error("not an environment");
    UNLOCK_FRAME(env);
    return R_NilValue;
}

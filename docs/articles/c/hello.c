#include "R.h"
#include "Rdefines.h"

#include <stdio.h>

SEXP hello_world(SEXP name) {
    char const msg_template[] = "Hello from C, %s!";
    char const *const c_name = CHAR(asChar(name));
    char *const msg_buf = R_alloc(sizeof msg_template - 2 + strlen(c_name) + 1, 1);
    sprintf(msg_buf, msg_template, c_name);
    return mkString(msg_buf);
}

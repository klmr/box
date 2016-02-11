


# Using *modules* to generate reusable R components

## Foreign language interface

Modules don’t have a built-in foreign language interface yet but it is possible
to effortlessly integrate C++ code via the excellent [Rcpp][] package.

As an example, take a look at the `rcpp` module found under `inst/demo`; the
module consists of a C++ source file which is loaded inside the `__init__.r`
file:

```r
Rcpp::sourceCpp(module_file('convolve.cpp'), env = environment())
```


Here’s the C++ code itself (the example is taken from the Rcpp documentation):

```cpp
#include "Rcpp.h"

using Rcpp::NumericVector;

// [[Rcpp::export]]
NumericVector convolve(NumericVector a, NumericVector b) {
    int na = a.size(), nb = b.size();
    int nab = na + nb - 1;
    NumericVector xab(nab);
    for (int i = 0; i < na; i++)
        for (int j = 0; j < nb; j++)
            xab[i + j] += a[i] * b[j];
    return xab;
}
```


This module can be used like any normal module:


```r
rcpp = import("rcpp")
ls(rcpp)
```

```
## [1] "convolve"
```

```r
rcpp$convolve(1:3, 1:5)
```

```
## [1]  1  4 10 16 22 22 15
```


---

Unfortunately, this has a rather glaring flaw: the code is recompiled for each
new R session. In order to avoid this, we need to compile the code *once* and
save the resulting dynamic library. There’s no straightforward way of doing
this, but Rcpp wraps `R CMD SHLIB`.

For the time being, we manually need to trigger compilation by executing the
[`__install__.r`][install.r] file found in the `inst/demo/rcpp` module path.

Once that’s done, the actual module code is easy enough:

```r
# Load compiled module meta information, and load R wrapper code, which, in
# turn, loads the compiled module via `dyn.load`.
load_dynamic = function (prefix) {
    load(module_file(sprintf('%s.rdata', prefix)))
    source(context$rSourceFile, local = parent.frame())
}

load_dynamic('convolve')
```


We can use it like any other module:


```r
compiled = import("rcpp/compiled")
compiled$convolve(1:3, 1:5)
```

```
## [1]  1  4 10 16 22 22 15
```


[Rcpp]: http://cran.r-project.org/web/packages/Rcpp/index.html
[install.r]: rcpp/__install__.r

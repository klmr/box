# Module access benchmark

> **Note:** This document describes internal implementation details.
> They are not required for users of the ‘box’ package and module
> authors.

## Purpose

Accessing a name in a module via `$` is expected to be an *extremely
common* operation, and will happen in tight loops. Performance is
therefore crucial. Furthermore, box overrides `$` for modules to prevent
partial matching (which the base R implementation does) and to provide
clean, relevant, informative error messages when a nonexistent name is
accessed.

This benchmark compares several implementations to choose the most
efficient one that still fulfils the design criteria.

## Scaffold

The following code generates mock modules for lookup with few and many
exported names as two representative cases. In fact, I don’t expect
there to be a big difference between them since even large modules will
typically have compartively few names (it might get more interesting
with thousands of names, but this isn’t a case we expect often, and
therefore don’t optimise for it).

And in fact using a hash table representation for typical module sizes
probably *adds* overhead; so we also test non-hashed environments.

We will arbitrarily use
[`utils::tail`](https://rdrr.io/r/utils/head.html) as the value that is
exported from the test modules. The reason for this is so that we can
compare performance with that of a package export (via `::`) and still
allow the bench package to validate that all expressions return the same
result (via implicit `check = TRUE`).

``` r

create_module = function (class, size, hash) {
    extra_objects = switch(
        size,
        small = list(),
        # 50 arbitrary names ought to do:
        large = as.list(setNames(nm = c(month.name, month.abb, letters)))
    )
    objects = c(extra_objects, name = utils::tail)
    structure(
        list2env(objects, parent = emptyenv(), hash = hash),
        class = if (class != 'baseline') class
    )
}
```

Some setup for compiling and loading native code:

``` r

load_native = function (name) {
    oldwd = setwd('extract')
    on.exit(setwd(oldwd))

    rbin = file.path(R.home('bin'), 'R')
    exitcode = system2(rbin, c('CMD', 'SHLIB', paste0(name, '.c')))
    stopifnot(exitcode == 0L)

    dll_path = file.path(getwd(), paste0(name, .Platform$dynlib.ext))
    getNativeSymbolInfo(name, dyn.load(dll_path))
}
```

## Implementations

### `[[` extract

This serves as a comparison, but the semantics are wrong: it does not
raise an error for nonexistent names; instead it returns `NULL`:

``` r

`$.mod_brackets` = function (e1, e2) {
    e1[[e2, exact = TRUE]]
}
```

### `get`

The simplest compliant implementation, though it creates terrible error
messages:

``` r

`$.mod_get` = function (e1, e2) {
    get(e2, envir = e1, inherits = FALSE)
}
```

### `get` + `tryCatch`

The following implementations avoid the error raised by `get` for a
nonexistent name and provide a better error message. The messages below
are placeholders — a real implementation would trade time and complexity
for a nicer error message (the performance of the error case is
irrelevant for us, so it is permitted to be slow).

The first implementation catches the error raised by `get` and raises a
different error instead:

``` r

`$.mod_try_catch_get` = function (e1, e2) {
    tryCatch(
        get(e2, envir = e1, inherits = FALSE),
        error = function (e) {
            stop('Nice error message')
        }
    )
}
```

### `get` + `%in% names(…)`

The next implementation adds an explicit check via lookup in the `names`
of the module environment:

``` r

`$.mod_in_names_get` = function (e1, e2) {
    if (! e2 %in% names(e1)) {
        stop('Nice error message')
    }
    get(e2, envir = e1, inherits = FALSE)
}
```

### `get` + `%in% ls(…)`

Instead of `names`, we can also use `ls` to enumerate an environment’s
name, but we need to remember to pass `all.names = TRUE`:

``` r

`$.mod_in_ls_get` = function (e1, e2) {
    if (! e2 %in% ls(e1, all.names = TRUE)) {
        stop('Nice error message')
    }
    get(e2, envir = e1, inherits = FALSE)
}
```

### `get` + `hasName`

`hasName(a, b)` does basically the same as `b %in% names(a)` but its
documentation claims that it is more efficient:

``` r

`$.mod_has_name_get` = function (e1, e2) {
    if (! hasName(e1, e2)) {
        stop('Nice error message')
    }
    get(e2, envir = e1, inherits = FALSE)
}
```

### `get` + `exists`

A more straightforward check for existence of a name in an environment
is `exists`:

``` r

`$.mod_exists_get` = function (e1, e2) {
    if (! exists(e2, envir = e1, inherits = FALSE)) {
        stop('Nice error message')
    }
    get(e2, envir = e1, inherits = FALSE)
}
```

### `get0`

It would be great if the `ifnotfound` argument to `get0` were lazily
evaluated: we could pass the error handling logic directly to `get0`, to
be evaluated only in the case of a nonexistent name. Alas, R does not
indulge us. We therefore need to use a sentinel value for `ifnotfound`
which is guaranteed to never be found in an actual module. Luckily this
is straightforward by using a new environment: R performs reference
identity checking for environments when passed to `identical`, meaning
that two environments compare identically if and only if they result
from the same creation via `new.env` (in particular, two environments
are *not* identical just because they happen to contain the same — or no
— contents).

In the implementation below this environment is reused between multiple
invocations. In theory, an enterprising user *could* extract this value
from the innards of box and export it from their own module. But this
wouldn’t happen by accident, and they deserve what they get.

Luckily for us, checking whether two environments are identical is also
efficient (R just compares their pointers):

``` r

`$.mod_get0` = function (e1, e2) {
    ret = get0(e2, e1, inherits = FALSE, ifnotfound = mod_get0_sentinel)
    if (identical(ret, mod_get0_sentinel)) {
        stop('Nice error message')
    }
    ret
}

mod_get0_sentinel = new.env()
```

### `get0` with handler in `on.exit`

We can avoid a temporary variable for the return value of `get0` by
moving the sentinel check into the `on.exit` handler. I find this rather
elegant, but I also suspect that it would be a lot less efficient:

``` r

`$.mod_on_exit_get0` = function (e1, e2) {
    on.exit(
        if (identical(returnValue(), mod_get0_sentinel)) {
            stop('Nice error message')
        }
    )
    get0(e2, e1, inherits = FALSE, ifnotfound = mod_get0_sentinel)
}
```

### `.Call` native code

Finally, we move to native code implementations. The actual lookup
implementation is always the same:

``` c
SEXP name = Rf_installTrChar(STRING_ELT(e2, 0));
SEXP ret = Rf_findVarInFrame(e1, name);
if (ret == R_UnboundValue) {
    // handle nonexistent name
}
return ret;
```

Where `e1` and `e2` refer to the module environment and the name,
respectively.

The first implementation is an unadorned `.Call` dispatch:

``` r

`$.mod_call` = function (e1, e2) {
    .Call(.c_call, e1, e2)
}

.c_call = load_native('call')
```

### `.Call` native code with `environment` argument

To generate nicer error messages, it is tempting to pass additional
information to the call (in particular, the calling environment):

``` r

`$.mod_call_env` = function (e1, e2) {
    .Call(.c_call_env, e1, e2, parent.frame())
}

.c_call_env = load_native('call_env')
```

### `.External` native code

An alternative way of invoking native code is via `.External`, which
looks the same on the calling (R) side of things:

``` r

`$.mod_external` = function (e1, e2) {
    .External(.c_external, e1, e2)
}

.c_external = load_native('external')
```

The only difference is that we need to manually unpack the arguments
from the pairlist on the C side:

``` c
SEXP e1 = CADR(args);
SEXP e2 = CADDR(args);
// etc.
```

### `.External` native code with `environment` argument

And once again, with an extra argument for better context in the error
message:

``` r

`$.mod_external_env` = function (e1, e2) {
    .External(.c_external_env, e1, e2, parent.frame())
}

.c_external_env = load_native('external_env')
```

## Benchmark

The following distinguishes “default”, where no class has been assigned
to the module (and thus the built-in environment type is used) and where
an S3 class is assigned but no `$` implement, so that the S3 dispatch
falls back to the default implementation. All other methods are
dispatched to a specific, custom method implementation of the `$`
generic. For good measure we also compare to qualified name lookup in a
package via `::`.

Before looking at the results, it is helpful to write down our
expectations, based on intuition and knowledge of the implementation of
the various methods. This will allow us to verify, to some extent, our
mental model of the R evaluation:

“baseline” and “default” will probably be the fastest cases since all
the work being done happens deep inside the R interpreter in native
code. It remains to be seen if our own native code implementation can
match their performance (*in principle* it could even surpass it, since
it needs to do less work by not performing partial matching). There
might also be a special case for “baseline” (where no S3 class is
assigned), and R might not perform S3 dispatch in this case at all.

`[[` and `get` both directly invoke native code (`[[` via `.Primitive`
and `get` via `.Internal`). However, `[[` can perform S3 dispatch so it
might be somewhat slower. Then again, `get` has more arguments that
might need to be evaluated eagerly.

Handling errors explicitly will inevitably add overhead. By looking at
the implementations, `tryCatch` adds a fair bit of R code. On the
opposite side, `names` is a primitive function, and `%in%` (via `match`)
is an internal function; but, compared to `tryCatch`, the `%in%` check
is performing a *redundant* test, so I have no clear expectation of what
method should be faster. `ls`, on the other hand, contains a non-trivial
amount of R logic, so I’d expect it to be strictly slower than `names`.
The documentation of `hasName` claims that it is more efficient than
`%in%` + `names` but given its implementation (in terms of `match` and
`names`) I don’t see how that would be possible.

Of all the ways of redundantly checking for nonexistent names, `exists`
should be the fastest since it is implemented as an `.Internal` function
and is more direct than the other ways; in particular, it can take
advantage of the internal hash table structure of the environment, which
none of the other methods can; however, this should only be an advantage
for unrealistically large modules. For real-world modules, using a hash
table for the environment probably makes no difference for lookup (at
worst it might actually *add* a small overhead compared to linear
scanning!).

`get0` is interesting: the documentation states that it is more
efficient than `exists` + `get`, but the documentation only addresses
the case where `ifnotfound = NULL`, which cannot be used here (`NULL` is
a legitimate value to export from a module!). Is it still more efficient
when calling `identical` with an environment instead of `is.null`?

… using `on.exit` to handle the sentinel value is almost certainly going
to be slower than doing it directly.

``` r

labels = c(
    baseline = 'baseline',
    default = 'default',
    brackets = '[[',
    get = 'get',
    try_catch_get = 'get + tryCatch',
    in_names_get = 'get + %in% names',
    in_ls_get = 'get + %in% ls',
    has_name_get = 'get + hasName',
    exists_get = 'get + exists',
    get0 = 'get0',
    on_exit_get0 = 'get0 + on.exit',
    call = '.Call',
    call_env = '.Call + env',
    external = '.External',
    external_env = '.External + env'
)

classes = names(labels)

cases = expand.grid(
    size = c('small', 'large'),
    hash = c(TRUE, FALSE),
    stringsAsFactors = FALSE
)

hash_label = function (hash) {
    c('hash', 'vec')[match(hash, c(TRUE, FALSE))]
}

modules = unlist(lapply(
    seq_len(nrow(cases)),
    function (row) {
        size = cases$size[row]
        hash = cases$hash[row]

        setNames(
            lapply(paste0('mod_', classes), create_module, size, hash),
            paste0(classes, '_', size, '_', hash_label(hash))
        )
    }
))

invisible(list2env(modules, .GlobalEnv))

combined_labels = unlist(lapply(
    seq_len(nrow(cases)),
    function (row) {
        size = cases$size[row]
        hash = cases$hash[row]
        sprintf('%s;%s;%s', labels, size, hash_label(hash))
    }
))

exprs = setNames(
    lapply(names(modules), function (mod) bquote(.(as.name(mod))$name)),
    combined_labels
)
all_exprs = c(exprs, `package;;;` = quote(utils::tail))

bm = bench::mark(iterations = 1e5, memory = FALSE, time_unit = 'us', exprs = all_exprs)
```

| method           | size  | hash | median \[µs\] |     itr/sec |
|:-----------------|:------|:-----|--------------:|------------:|
| baseline         | small | hash |          0.41 |  1895838.66 |
| default          | small | hash |          0.45 |  2022848.06 |
| \[\[             | small | hash |          1.07 |   766393.40 |
| get              | small | hash |          1.19 |   781764.23 |
| get + tryCatch   | small | hash |          3.61 |   257229.59 |
| get + %in% names | small | hash |          1.97 |   472686.92 |
| get + %in% ls    | small | hash |          4.76 |   194210.56 |
| get + hasName    | small | hash |          2.01 |   454018.18 |
| get + exists     | small | hash |          1.80 |   512407.14 |
| get0             | small | hash |          1.48 |   614068.88 |
| get0 + on.exit   | small | hash |          2.30 |   391451.49 |
| .Call            | small | hash |          0.74 |  1202451.06 |
| .Call + env      | small | hash |          0.90 |   986442.12 |
| .External        | small | hash |          0.78 |  1140924.18 |
| .External + env  | small | hash |          0.94 |   968424.95 |
| baseline         | large | hash |          0.41 |  2143726.95 |
| default          | large | hash |          0.41 |  2257403.02 |
| \[\[             | large | hash |          1.02 |   882020.77 |
| get              | large | hash |          1.15 |   783258.05 |
| get + tryCatch   | large | hash |          3.57 |   259851.13 |
| get + %in% names | large | hash |          2.38 |   339690.86 |
| get + %in% ls    | large | hash |         21.44 |    44723.03 |
| get + hasName    | large | hash |          2.42 |   375426.31 |
| get + exists     | large | hash |          1.80 |   482706.06 |
| get0             | large | hash |          1.48 |   620608.56 |
| get0 + on.exit   | large | hash |          2.30 |   393828.17 |
| .Call            | large | hash |          0.74 |  1125632.73 |
| .Call + env      | large | hash |          0.90 |  1000093.87 |
| .External        | large | hash |          0.82 |  1128872.26 |
| .External + env  | large | hash |          0.98 |   897684.35 |
| baseline         | small | vec  |          0.41 |  2202821.91 |
| default          | small | vec  |          0.41 |  2153910.53 |
| \[\[             | small | vec  |          1.02 |   876804.64 |
| get              | small | vec  |          1.15 |   816864.46 |
| get + tryCatch   | small | vec  |          3.53 |   259130.85 |
| get + %in% names | small | vec  |          1.84 |   508531.00 |
| get + %in% ls    | small | vec  |          4.59 |   199809.76 |
| get + hasName    | small | vec  |          1.89 |   483406.07 |
| get + exists     | small | vec  |          1.80 |   512011.48 |
| get0             | small | vec  |          1.48 |   600606.56 |
| get0 + on.exit   | small | vec  |          2.26 |   404742.77 |
| .Call            | small | vec  |          0.74 |  1235458.18 |
| .Call + env      | small | vec  |          0.94 |   958763.86 |
| .External        | small | vec  |          0.82 |  1142919.09 |
| .External + env  | small | vec  |          0.98 |   929089.19 |
| baseline         | large | vec  |          0.41 |  2172113.87 |
| default          | large | vec  |          0.41 |  1914847.88 |
| \[\[             | large | vec  |          1.02 |   879512.33 |
| get              | large | vec  |          1.15 |   799186.73 |
| get + tryCatch   | large | vec  |          3.57 |   240133.16 |
| get + %in% names | large | vec  |          2.21 |   404492.99 |
| get + %in% ls    | large | vec  |         20.91 |    45603.21 |
| get + hasName    | large | vec  |          2.30 |   382678.74 |
| get + exists     | large | vec  |          1.76 |   513232.19 |
| get0             | large | vec  |          1.48 |   615545.80 |
| get0 + on.exit   | large | vec  |          2.30 |   394596.38 |
| .Call            | large | vec  |          0.78 |  1184544.21 |
| .Call + env      | large | vec  |          0.90 |  1010368.60 |
| .External        | large | vec  |          0.82 |  1028760.80 |
| .External + env  | large | vec  |          0.94 |   969565.32 |
| package          |       |      |          0.08 | 11577653.36 |

Some observations:

- R code is *slow*, so any method that executes lots of it is slower
  than the alternatives which execute less of it. This doesn’t come as a
  big surprise, but the extent is still striking.
- It is reassuring to see that `hasName` is in fact identical in
  performance to `%in%` + `names`, contrary to what its documentation
  claims.
- All methods are **substantially** slower than the built-in lookup.
  This is disappointing: it adds a non-negligible, unavoidable overhead
  to every single qualified name lookup.
- Worse, even the best implementation is an order of magnitude slower
  than package name lookup via `::`, despite the fact that the latter
  first needs to check whether the package is already loaded. It’s great
  that `::` is fast, it’s not great that we are prevented from getting
  the same performance.
- Adding more arguments to the native calls adds a significant overhead:
  it makes them around 1.20±0.04 (±SD) times slower, and this is true
  for both the `.Call` and the `.External` calling conventions, and it
  occurs even when the arguments are not used.
- In R code, using a hashed *vs.* unhashed environment makes virtually
  no difference, except for large modules when checking via `%in%` +
  `names`. However, in compiled code, using a hashed environment is
  slightly but significantly faster.

### Correctness check

Ensure all of them (except for the baseline cases) throw an error when
an invalid name is queried:

``` r

invalid_exprs = lapply(exprs, function (e) `[[<-`(e, 3L, as.name('nam')))
self = environment()
exclude = grepl('^(baseline|default|\\[\\[);', names(invalid_exprs))

did_call_stop = vapply(
    invalid_exprs[! exclude],
    function (e) tryCatch({eval(e, self); FALSE}, error = function (.) TRUE),
    logical(1L)
)

stopifnot(all(did_call_stop))
```

## Trailer

`sessionInfo()` output

``` r

sessionInfo()
```

    ## R version 4.5.1 (2025-06-13)
    ## Platform: aarch64-apple-darwin20
    ## Running under: macOS Sequoia 15.7.3
    ## 
    ## Matrix products: default
    ## BLAS:   /Library/Frameworks/R.framework/Versions/4.5-arm64/Resources/lib/libRblas.0.dylib 
    ## LAPACK: /Library/Frameworks/R.framework/Versions/4.5-arm64/Resources/lib/libRlapack.dylib;  LAPACK version 3.12.1
    ## 
    ## locale:
    ## [1] en_GB.UTF-8/en_GB.UTF-8/en_GB.UTF-8/C/en_GB.UTF-8/en_GB.UTF-8
    ## 
    ## time zone: Europe/Zurich
    ## tzcode source: internal
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] vctrs_0.6.5       cli_3.6.5         knitr_1.50        rlang_1.1.6      
    ##  [5] xfun_0.54         bench_1.1.4       textshaping_1.0.4 jsonlite_2.0.0   
    ##  [9] glue_1.8.0        htmltools_0.5.8.1 ragg_1.5.0        sass_0.4.10      
    ## [13] rmarkdown_2.30    evaluate_1.0.5    jquerylib_0.1.4   tibble_3.3.0     
    ## [17] fastmap_1.2.0     yaml_2.3.10       lifecycle_1.0.4   compiler_4.5.1   
    ## [21] fs_1.6.6          pkgconfig_2.0.3   htmlwidgets_1.6.4 systemfonts_1.3.1
    ## [25] digest_0.6.39     R6_2.6.1          pillar_1.11.1     magrittr_2.0.4   
    ## [29] bslib_0.9.0       tools_4.5.1       pkgdown_2.2.0     cachem_1.1.0     
    ## [33] desc_1.4.3

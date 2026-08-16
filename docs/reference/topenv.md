# Get a module’s namespace environment

Called inside a module, `box::topenv()` returns the module namespace
environment. Otherwise, it behaves similarly to
[`topenv`](https://rdrr.io/r/base/ns-topenv.html).

## Usage

``` r
box::topenv()

box::topenv(env)
```

## Arguments

- module:

  a module environment

## Value

`box::topenv()` returns the top-level module environment of the module
it is called from, or the nearest top-level non-module environment
otherwise; this is usually `.GlobalEnv`.

`box::topenv(env)` returns the nearest top-level environment that is a
direct or indirect parent of `env`.

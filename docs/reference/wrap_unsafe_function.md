# Wrap “unsafe calls” functions

`wrap_unsafe_function` declares a function wrapper to a function that
causes an `R CMD check` NOTE when called directly. We should usually not
call these functions, but we need some of them because we want to
explicitly support features they provide.

## Usage

``` r
wrap_unsafe_function(ns, name)
```

## Arguments

- ns:

  The namespace of the unsafe function.

- name:

  The name of the unsafe function.

## Value

`wrap_unsafe_calls` returns a wrapper function with the same argument as
the wrapped function that can be called without causing a NOTE.

## Note

Using an implementation that simply aliases `getExportedValue` does not
work, since `R CMD check` sees right through this “ruse”.

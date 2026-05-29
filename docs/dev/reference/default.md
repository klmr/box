# Retrieve a value or a default

`a %||% b` returns `a` unless it is empty, in which case `b` is
returned.

## Usage

``` r
a %||% b

lhs %|% rhs
```

## Arguments

- a:

  the value to return if non-empty

- b:

  default value

- lhs:

  vector with potentially missing values, or `NULL`

- rhs:

  vector with default values, same length as `lhs` unless that is `NULL`

## Value

`a %||% b` returns `a`, unless it is `NULL`, empty, `FALSE` or `""`; in
which case `b` is returned.

`lhs %|% rhs` returns a vector of the same length as `rhs` with all
missing values in `lhs` replaced by the corresponding values in `rhs`.

# String formatting helpers

Interpolate expressions in a string

## Usage

``` r
fmt(..., envir = parent.frame())

chr(x)

html_escape(x)

interleave(a, b)
```

## Arguments

- ...:

  one or more unnamed character string arguments, followed optionally by
  named arguments

- x:

  an object to convert

- a:

  a character vector of length `n`

- b:

  a character vector of length `n - 1`

## Value

`fmt(...)` concatenates any unnamed arguments, and interpolates all
embedded expressions as explained in the ‘Details’. Named arguments are
treated as locally defined variables, and are added to (and override, in
case of name reuse) names defined in the calling scope.

`chr(x)` returns a string representation of a value or unevaluated
expression `x`.

`html_escape(x)` returns the HTML-escaped version of `x`.

`interleave(a, b)` returns a vector
`c(a[1], b[1], a[2], b[2], ..., a[n - 1], b[n - 1], a[n])`.

## Details

`fmt` interpolates embedded expressions in a string. `chr` converts a
value to a character vector; unlike `as.character`, it correctly
deparses unevaluated names and expressions. `interleave` is a helper
that interleaves two vectors `a = c(a[1], ..., a[n])` and
`b = c(b[1], ..., b[n - 1])`.

The general format of an interpolation expression inside a `fmt` string
is: `{...}` interpolates the expression `...`. To insert literal braces,
double them (i.e. `{{`, `}}`). Interpolated expressions can optionally
be followed by a *format modifier*: if present, it is specified via the
syntax `{...;modifier}`. The following modifiers are supported:

- `\"`:

  like `dQuote(...)`

- `\'`:

  like `sQuote(...)`

- `‹fmt›f`:

  like `sprintf('%‹fmt›f', ...)`

Vectors of length \> 1 will be concatenated as if using
[`toString`](https://rdrr.io/r/base/toString.html) before interpolation.

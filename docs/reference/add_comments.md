# Extend code regions to include leading comments and whitespace

Extend code regions to include leading comments and whitespace

## Usage

``` r
add_comments(refs)
```

## Arguments

- refs:

  a list of the code region `srcref`s to extend.

## Value

`add_comment` returns a list of `srcref`s corresponding to `srcref`, but
extended to include the preceding comment block.

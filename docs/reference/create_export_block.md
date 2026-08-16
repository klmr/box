# Collect export tag information

Collect export tag information

## Usage

``` r
create_export_block(expr, ref, info, mod_ns)

parse_object(info, expr, mod_ns)

roxygen2_object(alias, value, type)
```

## Arguments

- expr:

  The unevaluated expression represented by the tag.

- ref:

  The code reference `srcref` represented by the tag.

- alias:

  The object name.

- value:

  The object value.

- type:

  The object type.

## Value

`create_export_block` returns an object of type `roxy_block` represents
an exported declaration expression, along with its source code location.

## Note

This could be represented much simpler but we keep compatibility with
roxygen2 — at least for the time being — to make integration with the
roxygen2 API easier, should it become necessary.

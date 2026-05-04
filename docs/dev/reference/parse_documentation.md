# Parse a module’s documentation

Parse a module’s documentation

## Usage

``` r
parse_documentation(info, mod_ns)

parse_roxygen_tags(info, mod_ns)

patch_mod_doc(docs)
```

## Arguments

- info:

  The module info.

- mod_ns:

  The module namespace.

- docs:

  the list of roxygen2 documentation objects.

## Value

`parse_documentation` returns a list of character strings with the Rd
documentation source code for each documented name in a module.

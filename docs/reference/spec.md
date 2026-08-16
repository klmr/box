# Parse a mod or pkg spec expression passed to `use`

Parse a mod or pkg spec expression passed to `use`

## Usage

``` r
parse_spec(expr, alias)

mod_spec(spec, ...)

pkg_spec(spec, ...)

spec_name(spec)
```

## Arguments

- expr:

  the mod or pkg spec expression to parse

- alias:

  the mod or pkg spec alias as a character, or `NULL`

- spec:

  named list of information the parser constructed from a given spec
  expression

- ...:

  further information about a spec, not represented by the spec
  expression parse tree

## Value

`parse_spec` returns a named list that contains information about the
parsed mod specification. Currently it contains:

- `name`:

  the module or package name

- `prefix`:

  the prefix, if the spec is a module

- `attach`:

  a named vector of symbols to attach, or `TRUE` to attach all symbols,
  or `NULL` to attach nothing

- `alias`:

  the module or package alias

- `explicit`:

  a logical value indicating whether the caller provided an explicit
  alias

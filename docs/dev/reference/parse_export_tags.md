# Extract comment tags from Roxygen block comments

Extract comment tags from Roxygen block comments

## Usage

``` r
parse_export_tags(info, exprs, mod_ns)
```

## Arguments

- exprs:

  The unevaluated expressions to parse.

## Value

`parse_export_tags` returns a list of `roxy_block`s for all exported
declarations.

## Note

The following code performs the same function as roxygen2 with a custom
`@` tag roclet. Unfortunately roxygen2 itself pulls in many
dependencies, making it less suitable for an infrastructure package such
as this one. Furthermore, the code license of roxygen2 is incompatible
with ours, so we cannot simply copy and paste the relevant code out.
Luckily the logic is straightforward to reimplement.

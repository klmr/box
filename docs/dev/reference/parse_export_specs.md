# Find exported names in parsed module source

Find exported names in parsed module source

## Usage

``` r
parse_export_specs(info, exprs, mod_ns)

use_call

static_assign_calls

assign_calls

is_static_assign_call(call)

is_assign_call(call)

block_is_assign(block)

block_is_use_call(block)

block_is_exported(block)

block_name(block)
```

## Arguments

- info:

  The module info.

- exprs:

  The list of expressions of the parsed module.

- mod_ns:

  The module namespace after evaluating the expressions.

- call:

  A call to test.

- block:

  A roxygen2 block to inspect.

## Value

`parse_export_specs` returns a potentially empty character vector of
exported names.

## Note

There are two situations in which the `@export` tag can be applied:

1.  When applied to assignments, the assigned name is exported.

2.  When applied to a
    [`box::use`](https://klmr.me/box/dev/reference/use.md) call, the
    imported names are exported. This can be the module name itself, any
    attached names, or both. All names introduced by the
    [`box::use`](https://klmr.me/box/dev/reference/use.md) call are
    exported. See [`use`](https://klmr.me/box/dev/reference/use.md) for
    the rules governing what names are introduced into the scope, and
    thus exported.

In any other situation, applying the `@export` tag is an error.

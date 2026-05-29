# Explicitly declare module exports

`box::export` explicitly marks a source file as a box module. If can be
used as an alternative to the `@export` tag comment to declare a
module’s exports.

## Usage

``` r
box::export(...)
```

## Arguments

- ...:

  zero or more unquoted names that should be exported from the module.

## Value

`box::export` has no return value. It is called for its side effect.

## Details

`box::export` can be called inside a module to specify the module’s
exports. If a module contains a call to `box::export`, this call
overrides any declarations made via the `@export` tag comment. When a
module contains multiple calls to `box::export`, the union of all thus
defined names is exported.

A module can also contain an argument-less call to `box::export`. This
ensures that the module does not export any names. Otherwise, a module
that defines names but does not mark them as exported would be treated
as a *legacy module*, and all default-visible names would be exported
from it. Default-visible names are names not starting with a dot (`.`).
Another use of `box::export()` is to enable a module without exports to
use [module event
hooks](https://klmr.me/box/dev/reference/mod-hooks.md).

## Note

The preferred way of declaring exports is via the `@export` tag comment.
The main purpose of `box::export` is to explicitly prevent exports, by
being called without arguments.

## See also

[`box::use`](https://klmr.me/box/dev/reference/use.md) for information
on declaring exports via `@export`.

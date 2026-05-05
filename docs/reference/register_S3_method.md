# Register S3 methods

`box::register_S3_method` makes an S3 method for a given generic and
class known inside a module.

## Usage

``` r
box::register_S3_method(name, class, method)
```

## Arguments

- name:

  the name of the generic as a character string.

- class:

  the class name as a character string.

- method:

  the function to register as a method (optional).

## Value

`box::register_S3_method` is called for its side effect.

## Details

If `method` is missing, it defaults to a function named `name.class` in
the calling module. If no such function exists, an error is raised.

Methods for generics defined in the same module do not need to be
registered explicitly, and indeed *should not* be registered. However,
if the user wants to add a method for a known generic (defined outside
the module, e.g. [`print`](https://rdrr.io/r/base/print.html)), then
this needs to be made known explicitly.

See the vignette at
[`vignette('box', 'box')`](https://klmr.me/box/articles/box.md) for more
information about defining S3 methods inside modules.

## Note

**Do not** call
[`registerS3method`](https://rdrr.io/r/base/ns-internal.html) inside a
module, only use `box::register_S3_method`. This is important for the
module’s own book-keeping.

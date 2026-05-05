# Find the full paths of files in modules

Find the full paths of files in modules

## Usage

``` r
box::file(...)

box::file(..., module)
```

## Arguments

- ...:

  character vectors of files or subdirectories inside a module; if none
  is given, return the root directory of the module

- module:

  a module environment

## Value

A character vector containing the absolute paths to the files specified
in `...`.

## Note

If called from outside a module, the current working directory is used.

This function is similar to `system.file` for packages. Its semantics
differ in the presence of non-existent files: `box::file` always returns
the requested paths, even for non-existent files; whereas `system.file`
returns empty strings for non-existent files, or fails (if requested via
the argument `mustWork = TRUE`).

## See also

[`system.file`](https://rdrr.io/r/base/system.file.html)

# Information about a physical module or package

A `mod_info` represents an existing, installed module and its runtime
physical location (usually in the file system).

## Usage

``` r
mod_info(spec, source_path)

pkg_info(spec)
```

## Arguments

- spec:

  a `mod_spec` or `pkg_spec` (for `mod_info` and `pkg_info`,
  respectively)

- source_path:

  character string full path to the physical module location.

## Value

`mod_info` and `pkg_info` return a structure representing the
module/package information for the given specification/source location.

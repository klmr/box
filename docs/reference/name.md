# Get a module’s name

Get a module’s name

## Usage

``` r
box::name()
```

## Value

`box::name` returns a character string containing the name of the
module, or `NULL` if called from outside a module.

## Note

Because this function returns `NULL` if not invoked inside a module, the
function can be used to check whether a code is being imported as a
module or called directly.

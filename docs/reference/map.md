# Apply function to elements in list

`map` applies a function to lists of arguments, similar to `Map` in base
R, with the argument `USE.NAMES` set to `FALSE`. `flatmap` performs a
recursive map: the return type is always a vector of some type given by
the `.default`, and if the return value of calling `.f` is a vector, it
is flattened into the enclosing vector (see ‘Examples’). `transpose` is
a special `map` application that concatenates its inputs to compute a
transposed list.

## Usage

``` r
map(.f, ...)

flatmap(.f, ..., .default)

flatmap_chr(.f, ...)

vmap(.f, .x, ..., .default)

map_int(.f, ...)

map_lgl(.f, ...)

map_chr(.f, ...)

transpose(...)
```

## Arguments

- .f:

  an n-ary function where n is the number of further arguments given

- ...:

  lists of arguments to map over in parallel

- .default:

  the default value returned by `flatmap` for an empty input

## Value

`map` returns a (potentially nested) list of values resulting from
applying `.f` to the arguments.

`flatmap` returns a vector with type given by `.default`, or `.default`,
if the input is empty.

`transpose` returns a list of the element-wise concatenated input
vectors; that is, a “transposed list” of those elements.

## Examples


    flatmap_chr(identity, NULL)
    # character(0)

    flatmap_chr(identity, c('a', 'b'))
    # [1] "a" "b"

    flatmap_chr(identity, list(c('a', 'b'), 'c'))
    # [1] "a" "b" "c"

    transpose(1 : 2, 3 : 4)
    # [[1]]
    # [1] 1 3
    #
    # [[2]]
    # [1] 2 4

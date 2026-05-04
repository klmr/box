# Path related functions

`mod_search_path` returns the character vector of paths where module
code can be located and will be found by box.

## Usage

``` r
mod_search_path(caller)

calling_mod_path(caller)

split_path(path)

merge_path(components)

sanitize_path_fragment(path)
```

## Arguments

- caller:

  the environment from which
  [`box::use`](https://klmr.me/box/dev/reference/use.md) was invoked.

- path:

  the path

- components:

  character string vector of path components to merge

## Value

`calling_mod_path` the path of the source module that is calling
[`box::use`](https://klmr.me/box/dev/reference/use.md), or the script’s
path if the calling code is not a module.

`split_path` returns a character vector of path components that
logically represent `path`.

`merge_path` returns a single character string that is logically
equivalent to the `path` passed to `split_path`. logically represent
`path`.

## Note

The search paths are ordered from highest to lowest priority. The
current module’s path always has the lowest priority.

There are two ways of modifying the module search path: by default,
`getOption('box.path')` specifies the search path as a character vector.
Users can override its value by separately setting the environment
variable `R_BOX_PATH` to one or more paths, separated by the platform’s
path separator (“:” on UNIX-like systems, “;” on Windows).

`merge_path` is the inverse function to `split_path`. However, this does
not mean that its result will be identical to the original path.
Instead, it is only guaranteed that it will refer to the same logical
path given the same working directory.

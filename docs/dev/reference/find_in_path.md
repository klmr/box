# Find a module’s source location

Find a module’s source location

## Usage

``` r
find_in_path(spec, base_paths)
```

## Arguments

- spec:

  a `mod_spec`.

- base_paths:

  a character vector of paths to search the module in, in order of
  preference.

## Value

`find_in_path` returns a `mod_info` that specifies the module source
location.

## Details

A module is physically represented in the file system either by
`‹spec_name(spec)›.r` or by `‹spec_name(spec)›/__init__.r`, in that
order of preference in case both exist. File extensions are case
insensitive to allow for R’s obsession with capital-R extensions (but
lower-case are given preference, and upper-case file extensions are
discouraged).

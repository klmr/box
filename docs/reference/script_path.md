# Set the base path of the script

`box::set_script_path(path)` explicitly tells box the path of a given
script from which it is called; `box::script_path()` returns the
previously set path.

## Usage

``` r
box::set_script_path(path)

box::script_path()
```

## Arguments

- path:

  character string containing the relative or absolute path to the
  currently executing R code file, or `NULL` to reset the path.

## Value

Both `box::script_path` and `box::set_script_path` return the previously
set script path, or `NULL` if none was explicitly set.
`box::set_script_path` returns its value invisibly.

## Details

box needs to know the base path of the topmost calling R context (i.e.
the script) to find relative import locations. In most cases, box can
figure the path out automatically. However, in some cases third-party
packages load code in a way in which box cannot find the correct path of
the script any more. `box::set_script_path` can be used in these cases
to set the path of the currently executing R script manually.

## Note

box *should* be able to figure out the script path automatically. Using
`box::set_script_path` should therefore never be necessary. [Please file
an
issue](https://github.com/klmr/box/issues/new?assignees=&labels=%E2%9A%A0%EF%B8%8F+bug&title=%5Bset_script_path%5D%20&template=bug-report.yml)
if you encounter a situation that necessitates using
`box::set_script_path`!

## Examples

``` r
box::set_script_path('scripts/my_script.r')
```

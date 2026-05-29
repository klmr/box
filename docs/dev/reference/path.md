# Get a module’s path

The following functions retrieve information about the path of the
directory that a module or script is running in.

## Usage

``` r
path(mod)

base_path(mod)

module_path(mod)

mod_path(mod)

explicit_path(...)

r_path(...)

knitr_path(...)

shiny_path(...)

testthat_path(...)

rstudio_path(...)

wd_path(...)
```

## Arguments

- mod:

  a module environment or namespace

## Value

`path` returns a character string containing the module’s full path.

`base_path` returns a character string containing the module’s base
directory, or the current working directory if not invoked on a module.

`module_path` returns a character string that contains the directory in
which the calling R code is run. See ‘Details’.

`mod_path` returns the script path associated with a box module

`explicit_path` returns the script path explicitly set by the user, if
such a path was set.

`r_path` returns the directory in which the current script is run via
`Rscript`, `R CMD BATCH` or `R -f`.

`knitr_path` returns the directory in which the currently knit document
is run, or `NULL` if not called from within a knitr document.

`shiny_path` returns the directory in which a Shiny application is
running, or `NULL` if not called from within a Shiny application.

`testthat_path` returns the directory in which testthat code is being
executed, or `NULL` if not called from within a testthat test case.

`rstdio_path` returns the directory in which the currently active
RStudio script file is saved.

`wd_path` returns the current working directory.

## Details

`module_path` takes a best guess at a script’s path, since R does not
provide a sure-fire way for determining the path of the currently
executing code. The following calling situations are covered:

1.  Path explicitly set via `set_script_path`

2.  Path of a running document/application (knitr, Shiny)

3.  Path of unit test cases (testthat)

4.  Path of the currently opened source code file in RStudio

5.  Code invoked as `Rscript script.r`

6.  Code invoked as `R CMD BATCH script.r`

7.  Code invoked as `R -f script.r`

8.  Script run interactively (use
    [`getwd()`](https://rdrr.io/r/base/getwd.html))

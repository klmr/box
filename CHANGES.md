* 0.8.1:
    * Fix bug concerning wrong operator attachment for packages

* 0.8:
    * Add support for importing packages (#45)

* 0.7.3:
    * Add Shiny support (#53, rstudio/shinyapps#152)

* 0.7.2:
    * Fix building of vignette (#52)
    * Add support for knitr with help from @yihui (#31, yihui/knitr#950)

* 0.7.1:
    * Add a vignette
    * Fix operators whose name contains a dot

* 0.7:
    * Add support for S3 methods in modules

* 0.6.1:
    * Support aliases and illegal R names for documentation topics

* 0.6:
    * Add support for documentation via roxygen2 doc comments in modules

* 0.5:
    * Assume all module source files are UTF-8 encoded
    * Export non-function objects as well as functions
    * Lock exported namespace so that its symbols cannot be modified
    * Add `export_submodule` function
    * Improve documentation

* 0.4:
    * Make imports absolute by default, and add ability for explicit relative
      imports via the `./` or `../` prefix, and use the current script path as
      the base path, rather than the current working directory, when invoking a
      script via `R CMD BATCH` or `Rscript`
    * Do not change `getwd()` when `import`ing
    * Remove requirement for `__init__.r` as supermodule markers
    * Make `unload` and `reload` aware of globally attached modules
    * Fix `module_name` bug
    * Add `module_file` function which works akin to `system.file`
    * Pretty-print module objects
    * Support circular dependencies between modules
    * Fix (hopefully) installation on Windows by specifying project encoding

* 0.3:
    * Add capability of partially attaching modules

* 0.2:
    * Change the API to use quoted strings instead of unevaluated
      expressions, and slashes instead of dots to denote nested submodules
    * Attach operators even if other functions are not attached, to make them
      usable

* 0.1: Initial release

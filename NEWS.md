# box (development version)

* Feature: Add `topenv` function (#310)
* Fix: Work around R HTML help display regression that caused warnings (#255, #278)
* Fix: Support RStudio without installed ‘rstudioapi’ (#293)
* Fix: Make S3 method detection code more robust (#266)
* Fix: Support trailing comma in reexports (#263)
* Feature: Support lazy data loading for packages (#219)
* Enhancement: Improve error messages for invalid `use` declarations (#253)
* Feature: Add `purge_cache` function (@kamilzyla, #236)


# box 1.1.2

(Version update for technical reasons; no changes.)


# box 1.1.1

(Version update for technical reasons; no changes.)


# box 1.1.0

## Breaking changes

* Modules without any `@export` declarations now export all visible names (= names not starting with a dot). To restore the previous behaviour of a module without exports, call `box::export()` inside the module.
* `box::set_script_path()` now returns the *full* path previously set, as documented, not just its parent directory’s path. Existing code that relies on this function’s previously incorrect behaviour will need to be updated.

## Bug fixes

* Work around broken `isRunning()` function in Shiny ≥1.6.0 (#237).
* Return the full path from `box::set_script_path()`, as documented, not just the parent directory’s path; `box::script_path()` now also returns that path without requiring the user to set a new path (#239).
* Improve detection of whether code is called from inside RStudio (#225).
* Work around an R bug in path handling on non-Windows platforms when paths passed to the `R` binary contain spaces.
* Make HTML rendering of interactive module help work on Windows (#223).
* Prevent a segfault in R ≤ 3.6.1 caused by a missing declaration of an internal C symbol (#213).
* Allow exporting modules that were previously loaded using a different prefix (#211).
* Reload dependencies when reloading a module (#39, #165, #195).
* Don’t crash in the presence of nested, expanded functions inside modules (#203, #204).

## New and improved features

* Improve error messages when calling `box::unload()` or `box::reload()` with an invalid argument (#232).
* Improve error messages when a module cannot be found or when there’s a syntactic error in a `box::use()` declaration.
* Support legacy modules (aka. R scripts) better by exporting all visible names (#207).
* Permit specifying exports by calling `box::export()` instead of via `@export` declarations (#227).
* Add a standard module for core R packages (#200).
* Warn when legacy functions are imported inside modules (#206).
* Support modules without exports.


# box 1.0.2

## New and improved features

* Make `box::help()` work with attached objects (#170).
* Allow trailing comma in attach specification (#191).
* Allow loading the main module of a submdule via `box::use(.[...])` (#192).


# box 1.0.1

## Bug fixes

* `[...]` now correctly attaches exported names starting with a dot (#186).

## New and improved features

* Allow trailing comma in `box::use()` declaration (#172).
* Support loading local modules when executing files opened in RStudio (#187).
* Improve error message when accessing a non-existent module export via `$` (#180).
* Improve performance of accessing a module export via `$` (#180).
* Add explicit support for loading local modules inside ‘testthat’ unit tests (#188).


# box 1.0.0

Complete rewrite; see the [migration guide](https://klmr.me/box/articles/migration.html) for more information.


# modules 0.x

## modules 0.9.9

* Fix `module_file` argument check (#90)
* Add clickable links to “See also” section in documentation (#56)
* Fix a regression in the “basic-usage” vignette (#122)
* Dispatch calls to `` `?` `` and `help` to devtools, if necessary (#34)
* Run `document` twice to ensure S3 exports are correctly generated (#117, hadley/devtools#1585)
* Make Shiny runtime test more robust (#69)
* Fix crash in S3 recognition when function bodies have been substituted at runtime (#125)


## modules 0.9.8

* Fix missing S3 methods bug (#117)
* Fix missing exported operators (#93)


## modules 0.9.7

* Support rudimentary HTML help
* Fix `help(package = …)` (#38, #73)


## modules 0.9.6

* Fix broken interaction with Roxygen2 (#103)


## modules 0.9.5

* Locally attach ‹modules› inside modules (#44)


## modules 0.9.4

* Fix regression in 0.9 when ‹modules› package is not attached
* Fix `R CMD CHECK` warnings
* Fix missing documentation of `import` (#78)


## modules 0.9.3

* Fix regression in 0.9 due to attachment of operator environment (#71)
* Fix another typo in test for deprecation warning (from #68)


## modules 0.9.2

* Fix missing export of `export_submodule_` (#75)


## modules 0.9.1

* Fix typo in test for deprecation warning (from #68)
* Disable name conflict warning when run in non-interactive mode (#48)


## modules 0.9

* Fix wrong module name and path information after a module has been attached
  (#66, #67, #70)
* Deprecate usage of variables for package names (#68)


## modules 0.8.2

* Fix loading of a package that contains errors (#58)
* Fix `reload` overwriting the wrong object if its name is shadowed by the name
  of the reloaded module (#51)
* Fix loading of S3 generics without associated methods (#63)


## modules 0.8.1

* Fix bug concerning wrong operator attachment for packages


## modules 0.8

* Add support for importing packages (#45)
* Make module access operator `$` stricter
* Improve type checking (module access operator `$` is stricter, #55)


## modules 0.7.3

* Add Shiny support (#53, rstudio/shinyapps#152)


## modules 0.7.2

* Fix building of vignette (#52)
* Add support for knitr with help from @yihui (#31, yihui/knitr#950)


## modules 0.7.1

* Add a vignette
* Fix operators whose name contains a dot


## modules 0.7

* Add support for S3 methods in modules


## modules 0.6.1

* Support aliases and illegal R names for documentation topics


## modules 0.6

* Add support for documentation via roxygen2 doc comments in modules


## modules 0.5

* Assume all module source files are UTF-8 encoded
* Export non-function objects as well as functions
* Lock exported namespace so that its symbols cannot be modified
* Add `export_submodule` function
* Improve documentation


## modules 0.4

* Make imports absolute by default, and add ability for explicit relative imports via the `./` or `../` prefix, and use the current script path as the base path, rather than the current working directory, when invoking a script via `R CMD BATCH` or `Rscript`
* Do not change `getwd()` when `import`ing
* Remove requirement for `__init__.r` as supermodule markers
* Make `unload` and `reload` aware of globally attached modules
* Fix `module_name` bug
* Add `module_file` function which works akin to `system.file`
* Pretty-print module objects
* Support circular dependencies between modules
* Fix (hopefully) installation on Windows by specifying project encoding


## modules 0.3

* Add capability of partially attaching modules


## modules 0.2

* Change the API to use quoted strings instead of unevaluated expressions, and slashes instead of dots to denote nested submodules
* Attach operators even if other functions are not attached, to make them usable


## modules 0.1

Initial release

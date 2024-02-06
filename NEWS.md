# box 1.2.0

## Breaking changes

* *Deprecation warning:* in the next major version, ‘box’ will read the environment variable `R_BOX_PATH` only *once*, at package load time. Modifying its value afterwards will have no effect, unless the package is unloaded and reloaded.
* ‘box’ no longer supports R 3.5 since the R build infrastructure (in particular ‘devtools’) no longer supports it.

## Bug fixes

* Fix backports definitions so that they work in binary packages that were created using newer R versions (#347).
* Replace call to function that was added in R 4.0.0 to make package work again in R 3.6.3 (#335).

## New and improved features

* Prevent accidental misuse by checking that arguments to `box::file()` and `box::export()` are unnamed (#334).
* The `method` argument of `box::register_S3_method()` is now optional (#305).


# box 1.1.3

## Bug fixes

* Silence warnings caused by an internal change of the R HTML help display functionality (#255, #278).
* Support loading modules inside RStudio even when ‘rstudioapi’ is not installed (#293).
* Do not crash in the presence of missing arguments in function calls inside modules (#266).
* Support trailing comma in in reexports via `box::use()` (#263).

## New and improved features

* Add `box::topenv()` function, analogous to `base::topenv()` (#310).
* Support lazy loading data from packages (#219).
* Improve error messages for invalid `box::use()` declarations (#253).
* Add `box::purge_cache()` function to force reloading all modules (@kamilzyla, #236).


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

Older news can be found in `NEWS.0.md`.

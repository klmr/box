# Changelog

## box 1.2.2

CRAN release: 2026-04-10

### Miscellaneous

- Update the C implementation to adapt to R C API changes in R 4.6.0
  ([@ArcadeAntics](https://github.com/ArcadeAntics),
  [\#391](https://github.com/klmr/box/issues/391)).

## box 1.2.1

CRAN release: 2025-11-28

### Bug fixes

- Suppress a spurious internal warning upon reloading a module, caused
  by a dependent module being imported more than once
  ([\#363](https://github.com/klmr/box/issues/363)).

### Miscellaneous

- Changed the way environments are locked, since environment unlocking
  is no longer allowed by the CRAN policies.

## box 1.2.0

CRAN release: 2024-02-06

### Breaking changes

- *Deprecation warning:* in the next major version, ‘box’ will read the
  environment variable `R_BOX_PATH` only *once*, at package load time.
  Modifying its value afterwards will have no effect, unless the package
  is unloaded and reloaded.
- ‘box’ no longer supports R 3.5 since the R build infrastructure (in
  particular ‘devtools’) no longer supports it.

### Bug fixes

- Fix backports definitions so that they work in binary packages that
  were created using newer R versions
  ([\#347](https://github.com/klmr/box/issues/347)).
- Replace call to function that was added in R 4.0.0 to make package
  work again in R 3.6.3
  ([\#335](https://github.com/klmr/box/issues/335)).

### New and improved features

- Prevent accidental misuse by checking that arguments to
  [`box::file()`](https://klmr.me/box/reference/file.md) and
  [`box::export()`](https://klmr.me/box/reference/export.md) are unnamed
  ([\#334](https://github.com/klmr/box/issues/334)).
- The `method` argument of
  [`box::register_S3_method()`](https://klmr.me/box/reference/register_S3_method.md)
  is now optional ([\#305](https://github.com/klmr/box/issues/305)).

## box 1.1.3

CRAN release: 2023-05-02

### Bug fixes

- Silence warnings caused by an internal change of the R HTML help
  display functionality
  ([\#255](https://github.com/klmr/box/issues/255),
  [\#278](https://github.com/klmr/box/issues/278)).
- Support loading modules inside RStudio even when ‘rstudioapi’ is not
  installed ([\#293](https://github.com/klmr/box/issues/293)).
- Do not crash in the presence of missing arguments in function calls
  inside modules ([\#266](https://github.com/klmr/box/issues/266)).
- Support trailing comma in in reexports via
  [`box::use()`](https://klmr.me/box/reference/use.md)
  ([\#263](https://github.com/klmr/box/issues/263)).

### New and improved features

- Add [`box::topenv()`](https://klmr.me/box/reference/topenv.md)
  function, analogous to
  [`base::topenv()`](https://rdrr.io/r/base/ns-topenv.html)
  ([\#310](https://github.com/klmr/box/issues/310)).
- Support lazy loading data from packages
  ([\#219](https://github.com/klmr/box/issues/219)).
- Improve error messages for invalid
  [`box::use()`](https://klmr.me/box/reference/use.md) declarations
  ([\#253](https://github.com/klmr/box/issues/253)).
- Add [`box::purge_cache()`](https://klmr.me/box/reference/unload.md)
  function to force reloading all modules
  ([@kamilzyla](https://github.com/kamilzyla),
  [\#236](https://github.com/klmr/box/issues/236)).

## box 1.1.2

CRAN release: 2022-05-11

(Version update for technical reasons; no changes.)

## box 1.1.1

CRAN release: 2022-04-23

(Version update for technical reasons; no changes.)

## box 1.1.0

CRAN release: 2021-09-13

### Breaking changes

- Modules without any `@export` declarations now export all visible
  names (= names not starting with a dot). To restore the previous
  behaviour of a module without exports, call
  [`box::export()`](https://klmr.me/box/reference/export.md) inside the
  module.
- [`box::set_script_path()`](https://klmr.me/box/reference/script_path.md)
  now returns the *full* path previously set, as documented, not just
  its parent directory’s path. Existing code that relies on this
  function’s previously incorrect behaviour will need to be updated.

### Bug fixes

- Work around broken `isRunning()` function in Shiny ≥1.6.0
  ([\#237](https://github.com/klmr/box/issues/237)).
- Return the full path from
  [`box::set_script_path()`](https://klmr.me/box/reference/script_path.md),
  as documented, not just the parent directory’s path;
  [`box::script_path()`](https://klmr.me/box/reference/script_path.md)
  now also returns that path without requiring the user to set a new
  path ([\#239](https://github.com/klmr/box/issues/239)).
- Improve detection of whether code is called from inside RStudio
  ([\#225](https://github.com/klmr/box/issues/225)).
- Work around an R bug in path handling on non-Windows platforms when
  paths passed to the `R` binary contain spaces.
- Make HTML rendering of interactive module help work on Windows
  ([\#223](https://github.com/klmr/box/issues/223)).
- Prevent a segfault in R ≤ 3.6.1 caused by a missing declaration of an
  internal C symbol ([\#213](https://github.com/klmr/box/issues/213)).
- Allow exporting modules that were previously loaded using a different
  prefix ([\#211](https://github.com/klmr/box/issues/211)).
- Reload dependencies when reloading a module
  ([\#39](https://github.com/klmr/box/issues/39),
  [\#165](https://github.com/klmr/box/issues/165),
  [\#195](https://github.com/klmr/box/issues/195)).
- Don’t crash in the presence of nested, expanded functions inside
  modules ([\#203](https://github.com/klmr/box/issues/203),
  [\#204](https://github.com/klmr/box/issues/204)).

### New and improved features

- Improve error messages when calling
  [`box::unload()`](https://klmr.me/box/reference/unload.md) or
  [`box::reload()`](https://klmr.me/box/reference/unload.md) with an
  invalid argument ([\#232](https://github.com/klmr/box/issues/232)).
- Improve error messages when a module cannot be found or when there’s a
  syntactic error in a
  [`box::use()`](https://klmr.me/box/reference/use.md) declaration.
- Support legacy modules (aka. R scripts) better by exporting all
  visible names ([\#207](https://github.com/klmr/box/issues/207)).
- Permit specifying exports by calling
  [`box::export()`](https://klmr.me/box/reference/export.md) instead of
  via `@export` declarations
  ([\#227](https://github.com/klmr/box/issues/227)).
- Add a standard module for core R packages
  ([\#200](https://github.com/klmr/box/issues/200)).
- Warn when legacy functions are imported inside modules
  ([\#206](https://github.com/klmr/box/issues/206)).
- Support modules without exports.

## box 1.0.2

CRAN release: 2021-04-22

### New and improved features

- Make [`box::help()`](https://klmr.me/box/reference/help.md) work with
  attached objects ([\#170](https://github.com/klmr/box/issues/170)).
- Allow trailing comma in attach specification
  ([\#191](https://github.com/klmr/box/issues/191)).
- Allow loading the main module of a submdule via `box::use(.[...])`
  ([\#192](https://github.com/klmr/box/issues/192)).

## box 1.0.1

CRAN release: 2021-03-20

### Bug fixes

- `[...]` now correctly attaches exported names starting with a dot
  ([\#186](https://github.com/klmr/box/issues/186)).

### New and improved features

- Allow trailing comma in
  [`box::use()`](https://klmr.me/box/reference/use.md) declaration
  ([\#172](https://github.com/klmr/box/issues/172)).
- Support loading local modules when executing files opened in RStudio
  ([\#187](https://github.com/klmr/box/issues/187)).
- Improve error message when accessing a non-existent module export via
  `$` ([\#180](https://github.com/klmr/box/issues/180)).
- Improve performance of accessing a module export via `$`
  ([\#180](https://github.com/klmr/box/issues/180)).
- Add explicit support for loading local modules inside ‘testthat’ unit
  tests ([\#188](https://github.com/klmr/box/issues/188)).

## box 1.0.0

CRAN release: 2021-02-12

Complete rewrite; see the [migration
guide](https://klmr.me/box/articles/migration.html) for more
information.

Older news can be found in `NEWS.0.md`.

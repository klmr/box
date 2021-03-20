# Contribution guidelines

**Code …**

## … submissions

Please make all your pull requests against the [`main` branch][main] (this
is the default branch). No other pull requests will be accepted.

Please ensure all tests pass by running the tests and ideally `R CMD check`. On
systems with GNU Make, you can use the rules `make test` and `make check` for
this (run `make` without arguments for a complete list of build rules).

All new functions, also unexported ones, *must* be documented (documentation for
unexported functions must contain the `@keywords internal` Roxygen tag).

## … style

* Generally try to be consistent with the prevailing style in this project.
* Don’t use dots (`.`) in names, except for S3 dispatch; use underscore (`_`)
  to separate words.
* Don’t `"string-quote"` names; when using invalid names, use
  `` `backtick quotes` `` instead.
* Use `=` assignments, not `<-`.
* R code filenames must end in lower-case `.r`.

## … of conduct

This project expects all contributors to follow the standards laid down by the
[Contributor Covenant code of conduct][cccoc].

[cccoc]: CODE_OF_CONDUCT.md
[main]: https://github.com/klmr/box/tree/main

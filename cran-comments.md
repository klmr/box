## Re-submission to fix the following CRAN comments:

* Missing Rd-tags: I have fixed all missing `\value` tags in the documentation.

* Examples for unexported functions: I have removed all examples from internal
  documentation.

* Unwrap examples [from \dontrun{}]: I have modified the example for the use()
  function to be executable, and removed the \dontrun{} wrapper. The example
  code is executed inside a `local()` block to avoid it causing side-effects due
  to the example (by necessity) attaching environments and modifying global
  options. Other, non-runnable examples have been removed in favour of referring
  to the vignettes.

* Do not delete objects in examples or vignettes: The vignettes have been
  replaced by versions that no longer execute R code in the user environment,
  and therefore will not perform modifications/deletions. That said, I cannot
  explain this CRAN note: The previous vignettes were run in complete isolation:
  in particular, they did not delete any objects or files. The only object that
  was deleted was one that was previously created *inside the vignette*. No
  files were touched, except by an invocation of `R CMD SHLIB`.

* Do not modify the global environment: This package only modifies the *calling*
  environment (which may be the global environment), at the explicit direction
  of the user, and only according to fixed, clearly documented rules. Performing
  these modifications is the express purpose of this package. They are never
  unexpected or surprising side-effects. As noted, there is precedent for this
  behaviour in existing CRAN packages. In particular, the 'import' package
  modifies the calling environment in the same fashion via import::here().
  Likewise, the package 'zeallot' creates objects in the calling environment via
  the `%<-%` operator. I therefore believe that the modifications performed by
  this package are legitimate and in accordance with the CRAN policies: in
  particular, these actions are neither "malicious" nor "anti-social".


## Test environments

* Windows-latest (4.0.3)
* macOS-latest (4.0.3)
* ubuntu-20.04 (4.0.3)
* ubuntu-20.04 (devel)


## R CMD CHECK results

Status: 1 NOTE

New submission


## Original comments:

Please find attached a new package for your consideration.

The 'box' package implements a modern module system for R, incorporating design
lessons learned from module systems in other programming languages, and from a
previous version that has been used in production for over half a decade. This
previous version has found widespread interest in the community (seen e.g. by
its 240 GitHub stars). Its main accomplishment is making writing reusable code
vastly easier, by providing a powerful replacement for R's package mechanism as
well as ad-hoc modularisation using source().

The package _should_ pass all checks without errors, warnings or notes (besides
"New submission") on all platforms, and I believe that it follows all CRAN
submission rules. However, I would like to point out the following points of
interest:

* The main purpose of the package is to create names in the calling scope
  (including, in rare cases, via attach()). However, this only happens when the
  user specifically requests it, and will not cause confusion. There's precedent
  for this use-case (e.g. in the packages 'import' and 'devtools').

* The package itself is not supposed to be attached, and consequently should not
  be loaded via library() or require(). The .onAttach() handler of the package
  ensures this by raising an error with an informative message. This error is
  disabled during package installation and checking (based on the presence of
  the environment variables `R_INSTALL_PKG` and `_R_CHECK_PACKAGE_NAME_`).

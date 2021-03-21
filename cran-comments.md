## Changes

* Fix: Adjustment in test suite to fix a R CMD CHECK failure on WinBuilder when
  the capitalisation of the current working directory as returned from getwd()
  mismatches the actual capitalisation in the filesystem.

Other changes:

* Enhancement: Allow trailing comma in box::use()
* Enhancement: Support loading local modules from open files in RStudio
* Enhancement: improve error message and performance for module environment name
  access via `$`
* Enhancement: Add explicit support for 'testthat'
* Fix: Attach names starting with a dot


## Test environments

* r-release-windows
* r-release-macos-x86_64
* r-oldrel-linux-x86_64
* r-release-linux-x86_64
* r-devel-linux-x86_64


## R CMD CHECK results

Status: OK

## Major changes

This release of 'box' attempts to use a new style of documentation which diverges from the conventional R style, but which is (substantially) more appropriate for this package.

In particular, all uses of exported functions are explicitly qualified with the package name throughout the documentation, to mirror actual usage. Inside the \usage{} section, this is achieved via the use of \special{} tags.

Furthermore, the function box::use() permits multiple different syntax forms, akin to "overloads" in other languages, and these are documented as separate entries in the \usage{}. The \arguments{} section is adapted to match that. The resulting rendered documentation displays correctly in all common formats (text, HTML, PDF) so I hope that this is acceptable for CRAN submission.

## Test environments

* r-release-windows
* r-release-macos-x86_64
* r-oldrel-linux-x86_64
* r-release-linux-x86_64
* r-devel-linux-x86_64


## R CMD CHECK results

Status: OK

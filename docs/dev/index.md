# box

> Write Reusable, Composable and Modular R Code

[![CRAN status
badge](https://www.r-pkg.org/badges/version/box)](https://cran.r-project.org/package=box)
[![R-universe status
badge](https://klmr.r-universe.dev/badges/box)](https://klmr.r-universe.dev/)

- [Get started](https://klmr.me/box/articles/box.html)
- [Documentation](https://klmr.me/box/reference/index.html)
- [Contributing](https://klmr.me/box/articles/contributing.html)
- [Frequently asked questions](https://klmr.me/box/articles/faq.html)

## 📦 Installation

‘box’ can be installed from CRAN:

``` r
install.packages('box')
```

Alternatively, the current development version can be installed from
[R-universe](https://klmr.r-universe.dev/) (note that it *cannot* be
installed directly from GitHub!):

``` r
install.packages('box', repos = 'https://klmr.r-universe.dev')
```

## 🥜 Usage in a nutshell

‘box’ allows organising R code in a more modular way, via two
mechanisms:

1.  It enables *writing modular code* by treating files and folders of R
    code as independent (potentially nested) modules, without requiring
    the user to wrap reusable code into packages.
2.  It provides a new syntax to import reusable code (both from packages
    and modules) that is more powerful and less error-prone than
    `library` by allowing explicit control over what names to import,
    and by restricting the scope of the import.

### Reusable code modules

Code doesn’t have to be wrapped into an R package to be reusable. With
‘box’, regular R files are reusable **R modules** that can be used
elsewhere. Just put the **export directive** `#' @export` in front of
names that should be exported, e.g.:

``` r
#' @export
hello = function (name) {
    message('Hello, ', name, '!')
}

#' @export
bye = function (name) {
    message('Goodbye ', name, '!')
}
```

Existing R scripts without `@export` directives can also be used as
modules. In that case, all names inside the file will be exported,
unless they start with a dot (`.`).

Such modules can be stored in a central **module search path**
(configured via `options('box.path')`) analogous to the R package
library, or locally in individual projects. Let’s assume the module we
just defined is stored in a file `hello_world.r` inside a directory
`mod`, which is inside the module search path. Then the following code
imports and uses it:

``` r
box::use(mod/hello_world)

hello_world$hello('Ross')
#> Hello, Ross!
```

Modules are a lot like packages. But they are easier to write and use
(often without requiring any set-up), and they offer some other nice
features that set them apart from packages (such as the ability to be
nested hierarchically).

For more information on writing modules refer to the *[Get
started](https://klmr.me/box/articles/box.html)* vignette.

### Loading code

[`box::use`](https://klmr.me/box/dev/reference/use.md) provides a
**universal import declaration**. It works for packages just as well as
for modules. In fact, ‘box’ completely replaces the base R `library` and
`require` functions.
[`box::use`](https://klmr.me/box/dev/reference/use.md) is more explicit,
more flexible, and less error-prone than `library`. At its simplest, it
provides a direct replacement:

Instead of

``` r
library(ggplot2)
```

You’d write

``` r
box::use(ggplot2[...])
```

This tells R to import the ‘ggplot2’ package, and to make all its
exported names available (i.e. to “attach” them) — just like `library`.
For this purpose, `...` acts as a wildcard to denote “all exported
names”. However, attaching everything is generally *discouraged* (hence
why it needs to be done explicitly rather than happening implicitly),
since it leads to name clashes, and makes it harder to retrace which
names belong to what packages.

Instead, we can also instruct
[`box::use`](https://klmr.me/box/dev/reference/use.md) to not attach any
names when loading a package — or to just attach a few. Or we can tell
it to attach names under an alias, and we can also give the package
*itself* an alias.

The following [`box::use`](https://klmr.me/box/dev/reference/use.md)
declaration illustrates these different cases:

``` r
box::use(
    purrr,                          # 1
    tbl = tibble,                   # 2
    dplyr = dplyr[filter, select],  # 3
    stats[st_filter = filter, ...]  # 4
)
```

**Users of Python, JavaScript, Rust and many other programming languages
will find this `use` declaration familiar** (even if the syntax
differs):

The code

1.  *imports* the package ‘purrr’ (but does not attach any of its
    names);
2.  creates an *alias* `tbl` for the imported ‘tibble’ package (but does
    not attach any of its names);
3.  *imports* the package ‘dplyr’ and additionally *attaches* the names
    `dplyr::filter` and `dplyr::select`; and
4.  *attaches* all exported names from ‘stats’, but uses the local
    *alias* `st_filter` for the name
    [`stats::filter`](https://rdrr.io/r/stats/filter.html).

Of the four packages loaded in the code above, only ‘purrr’, ‘tibble’
and ‘dplyr’ are made available by name (as `purrr`, `tbl` and `dplyr`,
respectively), and we can use their exports via the `$` operator,
e.g. `purrr$map` or `tbl$glimpse`. Although we’ve also loaded ‘stats’,
we did not create a local name for the package itself, we only attached
its exported names.

Thanks to aliases, we can safely use functions with the same name from
multiple packages without conflict: in the above, `st_filter` refers to
the `filter` function from the ‘stats’ package; by contrast, plain
`filter` refers to the ‘dplyr’ function. Alternatively, we could also
explicitly qualify the package alias, and write `dplyr$filter`.

Furthermore, unlike with `library`, the effects of
[`box::use`](https://klmr.me/box/dev/reference/use.md) are restricted to
the current scope: we can load and attach names *inside* a function, and
this will not affect the calling scope (or elsewhere). So importing code
happens *locally*, and functions which load packages no longer cause
global side effects:

``` r
log = function (msg) {
    box::use(glue[glue])
    # We can now use `glue` inside the function:
    message(glue('[LOG MESSAGE] {msg}'))
}

log('test')
#> [LOG MESSAGE] test

# … But `glue` remains undefined in the outer scope:
glue('test')
#> Error in `glue()`:
#> ! could not find function "glue"
```

This makes it easy to encapsulate code with external dependencies
without creating unintentional, far-reaching side effects.

‘box’ itself is never loaded via `library`. Instead, its functionality
is always used explicitly via
[`box::use`](https://klmr.me/box/dev/reference/use.md).

## Getting help

If you encounter a bug or have a feature request, please [post an issue
report on GitHub](https://github.com/klmr/box/issues/new/choose). For
general questions, posting on Stack Overflow, [tagged as
r-box](https://stackoverflow.com/questions/tagged/r-box?tab=Newest), is
also an option. Finally, there’s a [GitHub
Discussions](https://github.com/klmr/box/discussions) board at your
disposal.

## Why ‘box’?

‘box’ makes it drastically easier to *write reusable code*: instead of
needing to create a package, each R code file *is already a module*
which can be imported using
[`box::use`](https://klmr.me/box/dev/reference/use.md). Modules can also
be nested inside directories, such that self-contained projects can be
easily split into separate or interdependent submodules.

To make code reuse more scalable for larger projects, ‘box’ promotes the
opposite philosophy of what’s common in R: some notable packages export
and attach many hundreds and, in at least one notable case, *over a
thousand* names. This works adequately for small-ish analysis scripts
but breaks down for even moderately large software projects because it
makes it non-obvious where names are imported from, and increases the
risk of name clashes.

To make code more explicit, readable and maintainable, software
engineering best practices encourage limiting both the scope of names,
as well as the number of names available in each scope.

For instance, best practice in Python is to never use the equivalent of
[`library(pkg)`](https://rdrr.io/r/base/library.html)
(i.e. `from pkg import *`). Instead, Python [strongly
encourages](https://www.python.org/dev/peps/pep-0008/#imports) using
`import pkg` or `from pkg import a, few, symbols`, which correspond to
`box::use(pkg)` and `box::use(pkg[a, few, symbols])`, respectively. The
same is true in many other languages,
e.g. [C++](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#Rs-using),
[Rust](https://doc.rust-lang.org/book/ch07-04-bringing-paths-into-scope-with-the-use-keyword.html#the-glob-operator)
and [Perl](https://perldoc.perl.org/Exporter#Selecting-What-to-Export).
Some languages (e.g. JavaScript) are even stricter: they don’t support
unqualified wildcard imports at all.

[*The Zen of Python*](https://www.python.org/dev/peps/pep-0020/) puts
this rule succinctly:

> **Explicit is better than implicit.**

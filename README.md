<!-- README.md is generated from README.rmd. Please edit that file instead! -->



# box <img src="man/figures/logo.png" align="right" alt="" width="120"/>

> Write Reusable, Composable and Modular R Code

## 📦 Installation

‘box’ can be installed from CRAN:


```r
install.packages('box')
```

Alternatively, the current development version can be installed from GitHub.
Note that the main branch cannot be installed directly, since it intentionally
misses generated files; instead, ‘box’ needs to be installed from the
auto-generated `dev` branch:


```r
if (! requireNamespace('pak') {
    install.packages('pak', repos = 'https://r-lib.github.io/p/pak/dev/')
}
pak::pkg_install('klmr/box@dev')
```

## 🥜 Usage in a nutshell

‘box’ allows organising R code in a more modular way, via two mechanisms:

1. It enables *writing modular code* by treating files and folders of R code as
   independent (potentially nested) modules, without requiring the user to wrap
   reusable code into packages.
2. It provides a new syntax to import reusable code (both from packages and from
   modules) which is more powerful and less error-prone than `library` or
   `require`, by limiting the number of names that are made available.

### Reusable code modules

Code doesn’t have to be wrapped into an R package to be reusable. With ‘box’,
regular R files form reusable **R modules** that can be used elsewhere. Just put
the **export directive** `#' @export` in front of names that should be exported,
e.g.:

```r
#' @export
hello = function (name) {
    message('Hello, ', name, '!')
}

#' @export
bye = function (name) {
    message('Goodbye ', name, '!')
}
```

Such modules can be stored in a central **module search path** (configured via
`options('box.path')`) analogous to the R package library, or locally in
individual projects. Let’s assume the module we just defined is stored in a file
`hello_world.r` inside a directory `box`, which is inside the module search
path. Then the following code imports and uses it:


```r
box::use(box/hello_world)

hello_world$hello('Ross')
#> Hello, Ross!
```

Modules are a lot like packages. But they are easier to write and use (often
without requiring any set-up), and they offer some other nice features that set
them apart from packages (such as the ability to be nested hierarchically).

For more information on writing modules refer to the *[Get started][]* vignette.

### Loading code

`box::use` is a **universal import declaration**. It works for packages just as
well as for modules. In fact, ‘box’ completely replaces the base R `library` and
`require` functions. `box::use` is more explicit, more flexible, and less
error-prone than `library`. At its simplest, it provides a direct replacement:

Instead of


```r
library(ggplot2)
```

You’d write


```r
box::use(ggplot2[...])
```

This tells R to import the ‘ggplot2’ package, and to make all its exported names
available (i.e. to “attach” them) — just like `library`. For this purpose, `...`
acts as a wildcard to denote “all exported names”. However, attaching everything
is generally *discouraged* (hence why it needs to be done explicitly rather than
happening implicitly), since it leads to name clashes, and makes it harder to
retrace which names belong to what packages.

Instead, we can also instruct `box::use` to not attach any names when loading a
package — or to just attach a few. Or we can tell it to attach names under an
alias, and we can also give the package *itself* an alias.

The following `box::use` declaration illustrates these different cases:


```r
box::use(
    purrr,                          # 1
    tbl = tibble,                   # 2
    dplyr = dplyr[filter, select],  # 3
    stats[st_filter = filter, ...]  # 4
)
```

**Users of Python, JavaScript, Rust and many other programming languages will
find this `use` declaration familiar** (even if the syntax differs):

The code

1. *imports* the package ‘purrr’ (but does not attach any of its names);
2. creates an *alias* `tbl` for the imported ‘tibble’ package (but does not
   attach any of its names);
3. *imports* the package ‘dplyr’ and additionally *attaches* the names
   `dplyr::filter` and `dplyr::select`; and
4. *attaches* all exported names from ‘stats’, but uses the local *alias*
   `st_filter` for the name `stats::filter`.

Of the four packages loaded in the code above, only ‘purrr’, ‘tibble’ and
‘dplyr’ are made available by name (as `purrr`, `tbl` and `dplyr`,
respectively), and we can use their exports via the `$` operator, e.g.
`purrr$map` or `tbl$glimpse`. Although we’ve also loaded ‘stats’, we did not
create a local name for the package itself, we only attached its exported names.

Thanks to aliases, we can safely use functions with the same name from multiple
packages without conflict: in the above, `st_filter` refers to the `filter`
function from the ‘stats’ package; by contrast, plain `filter` refers to the
‘dplyr’ function. Alternatively, we could also explicitly qualify the package
alias, and write `dplyr$filter`.

Furthermore, unlike with `library`, the effects of `box::use` are restricted to
the current scope: we can load and attach names *inside* a function, and this
will not affect the calling scope (or elsewhere). So importing code happens
*locally*, and functions which load packages no longer cause global side
effects:


```r
log = function (msg) {
    box::use(glue[glue])
    message(glue('[LOG MESSAGE] {msg}'))
}

log('test')
#> [LOG MESSAGE] test

# … 'glue' is still undefined at this point!
```

This makes it easy to encapsulate code with external dependencies without
creating unintentional, far-reaching side effects.

‘box’ itself is never loaded via `library`. Instead, its functionality is always
used explicitly via `box::use`.

## Why ‘box’?

‘box’ promotes the opposite philosophy of what’s common in R: some notable
packages export and attach many hundreds and, in at least one notable case,
*over a thousand* names. This works adequately for small-ish analysis scripts
but breaks down for even moderately large software projects because it makes it
non-obvious where names are imported from, and increases the risk of name
clashes.

To make code more explicit, readable and maintainable, software engineering best
practices encourage limiting both the scope of names, as well as the number of
names available in each scope.

For instance, best practice in Python is to never use the equivalent of
`library(pkg)` (i.e. `from pkg import *`). Instead, Python [strongly
encourages][pep8] using `import pkg` or `from pkg import a, few, symbols`, which
correspond to `box::use(pkg)` and `box::use(pkg[a, few, symbols])`,
respectively. The same is true in many other languages, e.g. [C++][], [Rust][]
and [Perl][]. Other languages (e.g. JavaScript and Go) are even stricter: they
don’t allow unqualified imports at all.

[*The Zen of Python*][pep20] puts this rule succinctly:

> Explicit is better than implicit.

‘box’ also makes it drastically easier to *write* reusable code: instead of
needing to create a package, each R code file *is already a module* which can be
imported using `box::use`. Modules can also be nested inside directories, such
that self-contained projects can be easily split into separate or interdependent
submodules.

[roxygen2]: https://roxygen2.r-lib.org/
[pep8]: https://www.python.org/dev/peps/pep-0008/#imports
[Get started]: https://klmr.me/box/articles/box.html
[C++]: https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#Rs-using
[Rust]: https://doc.rust-lang.org/book/ch07-04-bringing-paths-into-scope-with-the-use-keyword.html#the-glob-operator
[Perl]: https://perldoc.perl.org/Exporter#Selecting-What-to-Export
[pep20]: https://www.python.org/dev/peps/pep-0020/

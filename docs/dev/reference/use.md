# Import a module or package

`box::use` imports one or more modules and/or packages, and makes them
available in the calling environment.

## Usage

``` r
box::use(prefix/mod, ...)

box::use(pkg, ...)

box::use(alias = prefix/mod, ...)

box::use(alias = pkg, ...)

box::use(prefix/mod[attach_list], ...)

box::use(pkg[attach_list], ...)
```

## Arguments

- ...:

  further import declarations

- prefix/mod:

  a qualified module name

- pkg:

  a package name

- alias:

  an alias name

- attach_list:

  a list of names to attached, optionally with aliases of the form
  `alias = name`; or the special placeholder name `...`

## Value

`box::use` has no return value. It is called for its side effect.

## Details

`box::use(...)` specifies a list of one or more import declarations,
given as individual arguments to `box::use`, separated by comma.
`box::use` permits using a trailing comma after the last import
declaration. Each import declaration takes one of the following forms:

- `prefix``/``mod`::

  Import a module given the qualified module name `prefix``/``mod` and
  make it available locally using the name `mod`. The `prefix` itself
  can be a nested name to allow importing specific submodules. *Local
  imports* can be specified via the prefixes starting with `.` and `..`,
  to override the search path and use the local path instead. See the
  ‘Search path’ below for details.

- `pkg`::

  Import a package `pkg` and make it available locally using its own
  package name.

- `alias`` = ``prefix``/``mod` or `alias`` = ``pkg`::

  Import a module or package, and make it available locally using the
  name `alias` instead of its regular module or package name.

- `prefix``/``mod``[``attach_list``]` or `pkg``[``attach_list``]`::

  Import a module or package and attach the exported symbols listed in
  `attach_list` locally. This declaration does *not* make the
  module/package itself available locally. To override this, provide an
  alias, that is, use `alias`` = ``prefix``/``mod``[``attach_list``]` or
  `alias`` = ``pkg``[``attach_list``]`.

  The `attach_list` is a comma-separated list of names, optionally with
  aliases assigned via `alias = name`. The list can also contain the
  special symbol `...`, which causes *all* exported names of the
  module/package to be imported.

See the vignette at
[`vignette('box', 'box')`](https://klmr.me/box/dev/articles/box.md) for
detailed examples of the different types of use declarations listed
above.

## Import semantics

Modules and packages are loaded into dedicated namespace environments.
Names from a module or package can be selectively attached to the
current scope as shown above.

Unlike with [`library`](https://rdrr.io/r/base/library.html), attaching
happens *locally*, i.e. in the caller’s environment: if `box::use` is
executed in the global environment, the effect is the same. Otherwise,
the effect of importing and attaching a module or package is limited to
the caller’s local scope (its
[`environment()`](https://rdrr.io/r/base/environment.html)). When used
*inside a module* at module scope, the newly imported module is only
available inside the module’s scope, not outside it (nor in other
modules which might be loaded).

Member access of (non-attached) exported names of modules and packages
happens via the `$` operator. This operator does not perform partial
argument matching, in contrast with the behavior of the `$` operator in
base R, which matches partial names.

**Note** that replacement functions (i.e. functions of the form `fun<-`)
must be *attached* to be usable, because R syntactically does not allow
assignment calls where the left-hand side of the assignment contains
`$`.

## Export specification

Names defined in modules can be marked as *exported* by prefixing them
with an `@export` tag comment; that is, the name needs to be immediately
prefixed by a comment that reads, verbatim, `#' @export`. That line may
optionally be part of a roxygen2 documentation for that name.

Alternatively, exports may be specified via the
[`box::export`](https://klmr.me/box/dev/reference/export.md) function,
but using declarative `@export` tags is generally preferred.

A module which has not declared any exports is treated as a *legacy
module* and exports *all* default-visible names (that is, all names that
do not start with a dot (`.`)). This usage is present only for backwards
compatibility with plain R scripts, and its usage is *not recommended*
when writing new modules.

To define a module that exports no names, call
[`box::export()`](https://klmr.me/box/dev/reference/export.md) without
arguments. This prevents the module from being treated as a legacy
module.

## Search path

Modules are searched in the module search path, given by
`getOption('box.path')`. This is a character vector of paths to search,
from the highest to the lowest priority. The current directory is always
considered last. That is, if a file `a/b.r` exists both locally in the
current directory and in a module search path, the local file `./a/b.r`
will *not* be loaded, unless the import is explicitly declared as
`box::use(./a/b)`.

Modules in the module search path *must be organised in subfolders*, and
must be imported fully qualified. Keep in mind that `box::use(name)`
will *never* attempt to load a module; it always attempts to load a
package. A common module organisation is by project, company or user
name; for instance, fully qualified module names could mirror repository
names on source code sharing websites (such as GitHub).

Given a declaration `box::use(a/b)` and a search path `p`, if the file
`p``/a/b.r` does not exist, box alternatively looks for a nested file
`p``/a/b/__init__r` to load. Module path names are *case sensitive*
(even on case insensitive file systems), but the file extension can be
spelled as either `.r` or `.R` (if both exist, `.r` is given
preference).

The module search path can be overridden by the environment variable
`R_BOX_PATH`. If set, it may consist of one or more search paths,
separated by the platform’s path separator (i.e. `;` on Windows, and `:`
on most other platforms).

**Deprecation warning:** in the next major version, box will read
environment variables only *once*, at package load time. Modifying the
value of `R_BOX_PATH` afterwards will have no effect, unless the package
is unloaded and reloaded.

The *current directory* is context-dependent: inside a module, the
directory corresponds to the module’s directory. Inside an R code file
invoked from the command line, it corresponds to the directory
containing that file. If the code is running inside a Shiny application
or a knitr document, the directory of the execution is used. Otherwise
(e.g. in an interactive R session), the current working directory as
given by [`getwd()`](https://rdrr.io/r/base/getwd.html) is used.

Local import declarations (that is, module prefixes that start with `./`
or `../`) never use the search path to find the module. Instead, only
the current module’s directory (for `./`) or the parent module’s
directory (for `../`) is looked at. `../` can be nested: `../../`
denotes the grandparent module, etc.

## S3 support

Modules can contain S3 generics and methods. To override known generics
(= those defined outside the module), methods inside a module need to be
registered using
[`box::register_S3_method`](https://klmr.me/box/dev/reference/register_S3_method.md).
See the documentation there for details.

## Module names

A module’s full name consists of one or more R names separated by `/`.
Since `box::use` declarations contain R expressions, the names need to
be valid R names. Non-syntactic names need to be wrapped in backticks;
see [Quotes](https://rdrr.io/r/base/Quotes.html).

Furthermore, since module names usually correspond to file or folder
names, they should consist only of valid path name characters to ensure
portability.

## Encoding

All module source code files are assumed to be UTF-8 encoded.

## See also

[`box::name`](https://klmr.me/box/dev/reference/name.md) and
[`box::file`](https://klmr.me/box/dev/reference/file.md) give
information about loaded modules.
[`box::help`](https://klmr.me/box/dev/reference/help.md) displays help
for a module’s exported names.
[`box::unload`](https://klmr.me/box/dev/reference/unload.md) and
[`box::reload`](https://klmr.me/box/dev/reference/unload.md) aid during
module development by performing dynamic unloading and reloading of
modules in a running R session.
[`box::export`](https://klmr.me/box/dev/reference/export.md) can be used
as an alternative to `@export` comments inside a module to declare
module exports.

## Examples

``` r
# Set the module search path for the example module.
old_opts = options(box.path = system.file(package = 'box'))
old_env = Sys.getenv('R_BOX_PATH', NA)
Sys.unsetenv('R_BOX_PATH')

# Basic usage
# The file `mod/hello_world.r` exports the functions `hello` and `bye`.
box::use(mod/hello_world)
hello_world$hello('Robert')
#> Hello, Robert!
hello_world$bye('Robert')
#> Goodbye Robert!

# Using an alias
box::use(world = mod/hello_world)
world$hello('John')
#> Hello, John!

# Attaching exported names
box::use(mod/hello_world[hello])
hello('Jenny')
#> Hello, Jenny!
# Exported but not attached, thus access fails:
try(bye('Jenny'))
#> Error in bye("Jenny") : could not find function "bye"

# Attach everything, give `hello` an alias:
box::use(mod/hello_world[hi = hello, ...])
hi('Eve')
#> Hello, Eve!
bye('Eve')
#> Goodbye Eve!

# Reset the module search path
on.exit({
  options(old_opts)
  if (! is.na(old_env)) Sys.setenv(R_BOX_PATH = old_env)
})

if (FALSE) { # \dontrun{
# The following code illustrates different import declaration syntaxes
# inside a single `box::use` declaration:

box::use(
    global/mod,
    mod2 = ./local/mod,
    purrr,
    tbl = tibble,
    dplyr = dplyr[filter, select],
    stats[st_filter = filter, ...],
)

# This declaration makes the following names available in the caller’s scope:
#
# 1. `mod`, which refers to the module environment for  `global/mod`
# 2. `mod2`, which refers to the module environment for `./local/mod`
# 3. `purrr`, which refers to the package environment for ‘purrr’
# 4. `tbl`, which refers to the package environment for ‘tibble’
# 5. `dplyr`, which refers to the package environment for ‘dplyr’
# 6. `filter` and `select`, which refer to the names exported by ‘dplyr’
# 7. `st_filter`, which refers to `stats::filter`
# 8. all other exported names from the ‘stats’ package
} # }
```

# Get started

## Using modules

For the purpose of this tutorial, we are going to use the example module
`bio/seq`. The module implements some very basic mechanisms for dealing
with DNA sequences (= character strings consisting of the letters `A`,
`C`, `G` and `T`).

First, we load the module:

``` r

box::use(./bio/seq)
```

The function [`box::use`](https://klmr.me/box/reference/use.md) accepts
a list of *unquoted*, *qualified* module names. Each of these module
names will load a single module and make it available to the caller in
some form. In the code above, we’ve loaded a single module, `bio/seq`.
`bio` serves as a *parent module* that may group several submodules.
Since the module name inside
[`box::use`](https://klmr.me/box/reference/use.md) starts with `./`, the
module location is resolved *locally*, i.e. relative to the path of the
currently running code.

In the above, `seq` is the module’s *proper name*. `bio/seq` is its
*fully qualified name*. And `./bio/seq` is its *`use` declaration*.

To see the effect of this `use` declaration, let’s inspect our
workspace:

``` r

ls()
```

    ## [1] "seq"

``` r

seq
```

    ## <module: ./bio/seq>

We have used the module’s fully qualified name to load it. But, as shown
by `ls`, loading the module this way only introduces a single new name
into the current scope, the module itself, identified by its proper
(non-qualified) name.

To see which names a module exports, we use `ls` again, this time on the
module itself:

``` r

ls(seq)
```

    ## [1] "is_valid" "revcomp"  "seq"      "table"

It appears that `seq` exports 4 different names. To access exported
names, we use the `$` operator: `seq$is_valid` allows us to use the
first function in the list of exported names. We can also display the
interactive help for individual names using the
[`box::help`](https://klmr.me/box/reference/help.md) function, e.g.:

``` r

box::help(seq$revcomp)
```

Now let’s actually *use* the module. The `seq` function inside the
`bio/seq` module constructs a set of (optionally named) biological
sequences:

``` r

s = seq$seq(
    gene1 = 'GATTACAGATCAGCTCAGCACCTAGCACTATCAGCAAC',
    gene2 = 'CATAGCAACTGACATCACAGCG'
)

seq$is_valid(s)
```

    ## [1] TRUE

``` r

s
```

    ## 2 DNA sequences:
    ##   >gene1
    ##   GATTACAGATCAGCTCAGCACCTAGCA...
    ##   >gene2
    ##   CATAGCAACTGACATCACAGCG

Note how we automatically get pretty-printed
([FASTA](https://en.wikipedia.org/wiki/FASTA_format)) output because the
`print` method (which gets called implicitly here) is specialised for
the `'bio/seq'` S3 class in the `bio/seq` module (prefixing S3 classes
inside modules with the full module name is a convention to avoid name
clashes of S3 classes):

``` r

getS3method('print', 'bio/seq')
```

    ## function (x) {
    ##     box::use(stringr[trunc = str_trunc])
    ## 
    ##     if (is.null(names(x))) names(x) = paste('seq', seq_along(x))
    ## 
    ##     cat(
    ##         sprintf('%d DNA sequence%s:\n', length(x), if (length(x) == 1L) '' else 's'),
    ##         sprintf('  >%s\n  %s\n', names(x), trunc(x, 30L)),
    ##         sep = ''
    ##     )
    ##     invisible(x)
    ## }
    ## <environment: 0x126d47778>

The source code for `` `print.bio/seq` `` contains an interesting `use`
declaration: it showcases an alternative way of invoking
[`box::use`](https://klmr.me/box/reference/use.md), which we’ll explore
now.

## Attaching modules

Let’s have a look at alternative ways of using modules.

To start, let’s unload the `bio/seq` module …

``` r

box::unload(seq)
```

… and load it again, via a different route:

``` r

options(box.path = getwd())
box::use(bio/seq[revcomp, is_valid])
```

After unloading the already loaded module, `options(box.path = …)` sets
the module search path: this is where
[`box::use`](https://klmr.me/box/reference/use.md) searches for modules.
If more than one path is given,
[`box::use`](https://klmr.me/box/reference/use.md) searches them all
until a module of matching name is found. This works analogously to how
`.libPaths` operates on R packages.

The [`box::use`](https://klmr.me/box/reference/use.md) directive can now
use `bio/seq` instead of `./bio/seq` as the module name: rather than a
relative name we specify a *global* name. In this example we set the
search path to the current working directory but in normal usage it
would be a global library location, e.g. (following the [XDG base
directory
specification](https://specifications.freedesktop.org/basedir/latest/))
`~/.local/share/R/modules` on Linux.

**Note** that non-local module names *must* be fully qualified, nested
modules: `box::use(foo/bar)` works, `box::use(bar)` does not (instead,
it is assumed that `bar` refers to a *package*)!

In the declaration above we use `[revcomp, is_valid]` to specify that
the names `revcomp` and `is_valid` from the `bio/seq` module should be
attached in the calling environment. The `[…]` part is an *attach
specification*: a comma-separated list of names inside the parentheses
specifies which names to attach. The special symbol `...` can be used to
specify that *all exported names* should be attached. This has an effect
similar to conventional package loading via `library` (or `attach`ing an
environment): all the attached names are now available for direct use
without necessitating the `seq$` qualifier:

``` r

is_valid(s)
```

    ## [1] TRUE

``` r

revcomp(s)
```

    ## 2 DNA sequences:
    ##   >gene1
    ##   GTTGCTGATAGTGCTAGGTGCTGAGCT...
    ##   >gene2
    ##   CGCTGTGATGTCAGTTGCTATG

However, unlike the `attach` function, module attachment happens in the
*current, local scope* only.

Since the above code was executed in the global environment, there’s no
distinction between local and global scope:

``` r

search()
```

    ##  [1] ".GlobalEnv"        "mod:bio/seq"       "package:stats"    
    ##  [4] "package:graphics"  "package:grDevices" "package:utils"    
    ##  [7] "package:datasets"  "package:methods"   "Autoloads"        
    ## [10] "tools:callr"       "package:base"

Note the second item, which reads “`mod:bio/seq`”. But let’s now undo
that, to attach (and use) the module locally instead:

``` r

detach()

seq_table = function (s) {
    box::use(./bio/seq[...])
    table(s)
}

seq_table(s)
```

    ## $gene1
    ##  A  C  G  T 
    ## 13 12  6  7 
    ## 
    ## $gene2
    ## A C G T 
    ## 8 7 4 3

Unlike above, we are now attaching *all* exported names instead of
specifying individual names. The subsequent line of code uses the
`seq$table` function rather than
[`base::table`](https://rdrr.io/r/base/table.html) (which would have a
different output). And note that the `seq` module’s `table` function is
*not* attached outside the local scope:

``` r

search()
```

    ##  [1] ".GlobalEnv"        "package:stats"     "package:graphics" 
    ##  [4] "package:grDevices" "package:utils"     "package:datasets" 
    ##  [7] "package:methods"   "Autoloads"         "tools:callr"      
    ## [10] "package:base"

``` r

table(s)
```

    ## s
    ##                 CATAGCAACTGACATCACAGCG GATTACAGATCAGCTCAGCACCTAGCACTATCAGCAAC 
    ##                                      1                                      1

This is very powerful, as it isolates separate scopes more effectively
than the `attach` function. What is more, modules which are used and
attached inside another module *remain* inside that module and are not
visible outside the module by default.

Nevertheless, the normal, recommended usage of a module is without an
attach specification, as this makes it clearer which names are being
referring to.

## Writing modules

The module `bio/seq`, which we have used in the previous section, is
implemented in the file
[`bio/seq.r`](https://klmr.me/box/articles/bio/seq.r). The file `seq.r`
is, by and large, a regular R source file, which happens to live in a
directory named `bio`.

In fact, there are only three things worth mentioning:

1.  Documentation: functions in the module file can be documented using
    ‘[roxygen2](https://cran.r-project.org/package=roxygen2)’ syntax. It
    works the same as for packages. The ‘box’ package parses the
    documentation and makes it available via
    [`box::help`](https://klmr.me/box/reference/help.md). *Displaying
    module help requires that ‘roxygen2’ is installed.*

2.  Export declarations: similar to packages, modules explicitly need to
    declare which names they export; they do this using the annotation
    comment `#' @export` in front of the name assignment. Again, this
    works similarly to ‘roxygen2’ (but does *not* require having that
    package installed).

3.  [S3 functions](https://adv-r.hadley.nz/s3.html): ‘box’ registers and
    exports such functions automatically as necessary, but this only
    works for *user generics* that are defined inside the same module.
    When overriding “known generics” (such as `print`), we need to
    register these manually via `register_S3_method` (this is necessary
    since these functions are inherently ambiguous and there is no
    automatic way of finding them).

## Nesting modules

Modules can also form nested hierarchies. In fact, here is the
implementation of `bio` (in
[`bio/__init__.r`](https://klmr.me/box/articles/bio/__init__.r): since
`bio` is a directory rather than a file, the module implementation
resides in the nested file `__init__.r`):

``` r

#' @export
box::use(./seq)
```

The submodule is specified as `./seq` rather than `seq`: the explicitly
provided relative path prevents lookup in the import search path (that
we set via `options(box.path = …)`); instead, only the current directory
(that is, the directory containing the `bio` module) is considered.

When applied to a [`box::use`](https://klmr.me/box/reference/use.md)
declaration, `@export` causes all names which are imported by that
declaration to also be exported: any module name created by the
declaration (here, `seq`) is exported as-is. Furthermore, any attached
name is likewise exported. Refer to the
[`box::use`](https://klmr.me/box/reference/use.md) documentation and
examples for more details on which names are exported.

Coming back to our example module, we can now use the `bio` module:

``` r

options(box.path = NULL) # Reset search path
box::use(./bio)
ls(bio)
```

    ## [1] "seq"

``` r

ls(bio$seq)
```

    ## [1] "is_valid" "revcomp"  "seq"      "table"

``` r

bio$seq$revcomp('CAT')
```

    ## 1 DNA sequence:
    ##   >seq 1
    ##   ATG

We could also have implemented `bio` as follows:

``` r

#' @export
box::use(./seq[...])
```

This would have made all of `seq`’s definitions immediately available in
`bio`, without having to always write `seq$…`. This is sometimes useful,
but should be employed with care: being explicit about namespaces
generally increases code robustness and readability.

## Code execution on loading

Modules define functions and values. To execute code when a module is
loaded, put it inside a function with the name `.on_load`. This function
is similar to the hook for the `.onLoad` *package* namespace event.

This function is executed the first time the module is loaded in an R
session. Subsequent calls to
[`box::use`](https://klmr.me/box/reference/use.md) for that module,
regardless of whether they occur in a different scope, will refer to the
already loaded, cached module, and will *not* reload the module.

We can illustrate this by loading a module which has side-effects,
`info`.

``` r

.on_load = function (ns) {
    message(
        'Loading module "', box::name(), '"\n',
        'Module path: "', basename(box::file()), '"'
    )
}

box::export() # Mark as a ‘box’ module.
```

Let’s use it:

``` r

box::use(./info)
```

    ## Loading module "info"
    ## Module path: "vignettes"

We have imported the module, and get the diagnostic messages. Let’s
re-use the module:

``` r

box::use(./info)
```

… no messages are displayed. However, we *can* explicitly reload a
module. This clears the cache, and loads the module again. This can be
useful during development and debugging:

``` r

box::reload(info)
```

    ## Loading module "info"
    ## Module path: "vignettes"

And this displays the messages again. The `reload` function is a
shortcut for `unload` followed by `import` (using the exact same
arguments as used on the original `import` call).

### Module helper functions

This `info` module also show-cases two important helper functions:

1.  [`box::name`](https://klmr.me/box/reference/name.md) returns the
    name of the module with which it was loaded. This is especially
    handy because, when called outside of a module,
    [`box::name`](https://klmr.me/box/reference/name.md) is `NULL`. This
    allows testing whether a piece of code was loaded as a module, or
    invoked directly (e.g. via `Rscript` on the command line).

2.  [`box::file`](https://klmr.me/box/reference/file.md) is similar to
    `system.file`: it returns the full path to any file within the
    directory where a module is stored. This is useful when distributing
    data files with modules, which are loaded from within the module.
    When invoked without arguments,
    [`box::file`](https://klmr.me/box/reference/file.md) returns the
    full path to the directory containing the module source file.

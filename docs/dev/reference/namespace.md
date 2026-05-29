# Module namespace handling

`make_namespace` creates a new module namespace.

## Usage

``` r
make_namespace(info)

is_namespace(env)

namespace_info(ns, which, default = NULL)

namespace_info(ns, which) <- value

mod_topenv(env = parent.frame())

is_mod_topenv(env)
```

## Arguments

- info:

  the module info.

- env:

  an environment that may be a module namespace.

- ns:

  the module namespace environment.

- which:

  the key (as a length 1 character string) of the info to get/set.

- default:

  default value to use if the key is not set.

- value:

  the value to assign to the specified key.

## Value

`make_namespace` returns the newly created module namespace for the
module described by `info`.

## Details

The namespace contains a module’s content. This schema is very much like
R package organisation. A good resource for this is:
\<http://obeautifulcode.com/R/How-R-Searches-And-Finds-Stuff/\>

## Note

Module namespaces aren’t actual R package namespaces. This is
intentional, since R makes strong assumptions about package namespaces
that are violated here. In particular, such namespaces would have to be
registered in R’s internal namespace registry, and their
(de)serialisation is handled by R code which assumes that they belong to
actual packges that can be loaded via \`loadNamespace\`.

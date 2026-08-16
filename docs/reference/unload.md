# Unload or reload modules

Given a module which has been previously loaded and is assigned to an
alias `mod`, `box::unload(mod)` unloads it; `box::reload(mod)` unloads
and reloads it from its source. `box::purge_cache()` marks all modules
as unloaded.

## Usage

``` r
box::unload(mod)

box::reload(mod)

box::purge_cache()
```

## Arguments

- mod:

  a module object to be unloaded or reloaded

## Value

These functions are called for their side effect. They do not return
anything.

## Details

Unloading a module causes it to be removed from the internal cache such
that the next subsequent
[`box::use`](https://klmr.me/box/reference/use.md) declaration will
reload the module from its source. `box::reload` unloads and reloads the
specified modules and all its transitive module dependencies.
`box::reload` is *not* merely a shortcut for calling `box::unload`
followed by [`box::use`](https://klmr.me/box/reference/use.md), because
`box::unload` only unloads the specified module itself, not any
dependent modules.

## Note

Any other references to the loaded modules remain unchanged, and will
(usually) still work. Unloading and reloading modules is primarily
useful for testing during development, and *should not be used in
production code:* in particular, unloading may break other module
references if the `.on_unload` hook unloaded any binary shared libraries
which are still referenced.

These functions come with a few restrictions. `box::unload` attempts to
detach names attached by the corresponding
[`box::use`](https://klmr.me/box/reference/use.md) call. `box::reload`
attempts to re-attach these same names. This only works if the
corresponding [`box::use`](https://klmr.me/box/reference/use.md)
declaration is located in the same scope. `box::purge_cache` only
removes the internal cache of modules, it does not actually invalidate
any module references or names attached from loaded modules.

`box::unload` will execute the `.on_unload` hook of the module, if it
exists. `box::reload` will re-execute the `.on_load` hook of the module
and of all dependent modules during loading (after executing the
corresponding `.on_unload` hooks during unloading). `box::purge_cache`
will execute any existing `.on_unload` hooks in all loaded modules.

## See also

[`box::use`](https://klmr.me/box/reference/use.md), [module
hooks](https://klmr.me/box/reference/mod-hooks.md)

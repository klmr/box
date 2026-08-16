# Hooks for module events

Modules can declare functions to be called when a module is first
loaded.

## Usage

``` r
.on_load(ns)

.on_unload(ns)
```

## Arguments

- ns:

  the module namespace environment

## Value

Any return values of the hook functions are ignored.

## Details

To create module hooks, modules should define a function with the
specified name and signature. Module hooks should *not* be exported.

When `.on_load` is called, the unlocked module namespace environment is
passed to it via its parameter `ns`. This means that code in `.on_load`
is permitted to modify the namespace by adding names to, replacing names
in, or removing names from the namespace.

`.on_unload` is called when modules are unloaded. The (locked) module
namespace is passed as an argument. It is primarily useful to clean up
resources used by the module. Note that, as for packages, `.on_unload`
is *not* necessarily called when R is shut down.

*Legacy modules* cannot use hooks. To use hooks, the module needs to
contain an export specification (if the module should not export any
names, specify an explicit, empty export list via
[`box::export()`](https://klmr.me/box/reference/export.md).

## Note

The API for hook functions is still subject to change. In particular,
there might in the future be a way to subscribe to module events of
other modules and packages, equivalently to R package userhooks.

# Environment of loaded modules

Each module is stored as an environment inside `loaded_mods` with the
module’s code location path as its identifier. The path rather than the
module name is used because module names are not unique: two modules
called `a` can exist nested inside modules `b` and `c`, respectively.
Yet these may be loaded at the same time and need to be distinguished.

## Usage

``` r
loaded_mods

is_mod_loaded(info)

register_mod(info, mod_ns)

deregister_mod(info)

loaded_mod(info)

is_mod_still_loading(info)

mod_loading_finished(info, mod_ns)
```

## Format

`loaded_mods` is an environment of the loaded module and package
namespaces.

## Arguments

- info:

  the mod info of a module

- mod_ns:

  module namespace environment

## Details

`is_mod_loaded` tests whether a module is already loaded.

`register_mod` caches a module namespace and marks the module as loaded.

`deregister_mod` removes a module namespace from the cache, unloading
the module from memory.

`loaded_mod` retrieves a loaded module namespace given its info.

`is_mod_still_loading` tests whether a module is still being loaded.

`mod_loading_finished` signals that a module has been completely loaded.

## Note

`is_mod_still_loading` and `mod_loading_finished` are used to break
cycles during the loading of modules with cyclic dependencies.

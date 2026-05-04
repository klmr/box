# Import a module or package

Actual implementation of the import process

## Usage

``` r
use_one(declaration, alias, caller, use_call)

load_and_register(spec, info, caller)

register_as_import(spec, info, mod_ns, caller)

defer_import_finalization(spec, info, mod_ns, caller)

finalize_deferred(info)

export_and_attach(spec, info, mod_ns, caller)

load_from_source(info, mod_ns)

load_mod(info)

mod_exports(info, spec, mod_ns)

mod_export_names(info, mod_ns)

attach_to_caller(spec, info, mod_exports, mod_ns, caller)

attach_list(spec, exports)

assign_alias(spec, mod_exports, caller)

assign_temp_alias(spec, caller)
```

## Arguments

- declaration:

  an unevaluated use declaration expression without the surrounding
  `use` call

- alias:

  the use alias, if given, otherwise `NULL`

- caller:

  the client’s calling environment (parent frame)

- use_call:

  the `use` call which is invoking this code

- spec:

  a module use declaration specification

- info:

  the physical module information

- mod_ns:

  the module namespace environment of the newly loaded module

## Value

`use_one` does not currently return a value. — This might change in the
future.

`load_mod` returns a named `list(mod_ns, is_apex)` containing the module
or package namespace environment of the specified module or package
info, as well as a flag specifying whether the loaded module is an
“apex” module, i.e. not loaded from within another module. This
information is then used to lock all environments that were created
during the loading. — This must happen after nested modules are fully
loaded, since deferred finalization otherwise cannot modify these
environments during cyclic imports.

`mod_exports` returns an export environment containing the exported
names of a given module.

`mode_export_names` returns a vector containing the same names as
`names(mod_exports(info, spec, mod_ns))` but does not create an export
environment.

`attach_list` returns a named character vector of the names in an attach
specification. The vector’s names are the aliases, if provided, or the
attach specification names themselves otherwise.

## Details

`use_one` performs the actual import. It is invoked by `use` given the
calling context and unevaluated expressions as arguments, and only uses
standard evaluation.

`load_and_register` performs the loading, attaching and exporting of a
module identified by its spec and info.

`register_as_import` registers a `use` declaration in the calling module
so that it can be found later on, if the declaration is reexported by
the calling module.

`defer_import_finalization` is called by `load_and_register` to earmark
a module for deferred initialization if it hasn’t been fully loaded yet.

`finalize_deferred` exports and attaches names from a module use
declaration which has been deferred due to being part of a cyclic
loading chain.

`export_and_attach` exports and attaches names from a given module use
declaration.

`load_from_source` loads a module source file into its newly created,
empty module namespace.

`load_mod` tests whether a module or package was already loaded and, if
not, loads it.

`mod_exports` returns an export environment containing a copy of the
module’s exported objects.

`attach_to_caller` attaches the listed names of an attach specification
for a given use declaration to the calling environment.

`assign_alias` creates a module/package object in calling environment,
unless it contains an attach declaration, and no explicit alias is
given.

`assign_temp_alias` creates a placeholder object for the module in the
calling environment, to be replaced by the actual module export
environment once the module is completely loaded (which happens in the
case of cyclic imports).

## Note

If a module is still being loaded (because it is part of a cyclic import
chain), `load_and_register` earmarks the module for deferred
registration and holds off on attaching and exporting for now, since not
all its names are available yet.

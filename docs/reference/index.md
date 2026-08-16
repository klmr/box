# Package index

## Using modules & packages

Functions for users of modules and packages

- [`use()`](https://klmr.me/box/reference/use.md) : Import a module or
  package

## Writing modules

Infrastructure and utility functions for use inside modules

- [`export()`](https://klmr.me/box/reference/export.md) : Explicitly
  declare module exports
- [`file()`](https://klmr.me/box/reference/file.md) : Find the full
  paths of files in modules
- [`name()`](https://klmr.me/box/reference/name.md) : Get a module’s
  name
- [`register_S3_method()`](https://klmr.me/box/reference/register_S3_method.md)
  : Register S3 methods
- [`topenv()`](https://klmr.me/box/reference/topenv.md) : Get a module’s
  namespace environment
- [`.on_load()`](https://klmr.me/box/reference/mod-hooks.md)
  [`.on_unload()`](https://klmr.me/box/reference/mod-hooks.md) : Hooks
  for module events

## Interactive use

Functions for use in interactive sessions and for testing

- [`help()`](https://klmr.me/box/reference/help.md) : Display module
  documentation
- [`unload()`](https://klmr.me/box/reference/unload.md)
  [`reload()`](https://klmr.me/box/reference/unload.md)
  [`purge_cache()`](https://klmr.me/box/reference/unload.md) : Unload or
  reload modules
- [`set_script_path()`](https://klmr.me/box/reference/script_path.md)
  [`script_path()`](https://klmr.me/box/reference/script_path.md) : Set
  the base path of the script

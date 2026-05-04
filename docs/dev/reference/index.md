# Package index

## Using modules & packages

Functions for users of modules and packages

- [`use()`](https://klmr.me/box/dev/reference/use.md) : Import a module
  or package

## Writing modules

Infrastructure and utility functions for use inside modules

- [`export()`](https://klmr.me/box/dev/reference/export.md) : Explicitly
  declare module exports
- [`file()`](https://klmr.me/box/dev/reference/file.md) : Find the full
  paths of files in modules
- [`name()`](https://klmr.me/box/dev/reference/name.md) : Get a module’s
  name
- [`register_S3_method()`](https://klmr.me/box/dev/reference/register_S3_method.md)
  : Register S3 methods
- [`topenv()`](https://klmr.me/box/dev/reference/topenv.md) : Get a
  module’s namespace environment
- [`.on_load()`](https://klmr.me/box/dev/reference/mod-hooks.md)
  [`.on_unload()`](https://klmr.me/box/dev/reference/mod-hooks.md) :
  Hooks for module events

## Interactive use

Functions for use in interactive sessions and for testing

- [`help()`](https://klmr.me/box/dev/reference/help.md) : Display module
  documentation
- [`unload()`](https://klmr.me/box/dev/reference/unload.md)
  [`reload()`](https://klmr.me/box/dev/reference/unload.md)
  [`purge_cache()`](https://klmr.me/box/dev/reference/unload.md) :
  Unload or reload modules
- [`set_script_path()`](https://klmr.me/box/dev/reference/script_path.md)
  [`script_path()`](https://klmr.me/box/dev/reference/script_path.md) :
  Set the base path of the script

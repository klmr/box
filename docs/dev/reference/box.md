# An alternative module system for R

Use `box::use(prefix/mod)` to import a module, or `box::use(pkg)` to
import a package. Fully qualified names are supported for nested
modules, reminiscent of module systems in many other modern languages.

## Using modules & packages

- [`box::use`](https://klmr.me/box/dev/reference/use.md)

## Writing modules

Infrastructure and utility functions that are mainly used inside
modules.

- [`box::file`](https://klmr.me/box/dev/reference/file.md)

- [`box::name`](https://klmr.me/box/dev/reference/name.md)

- [`box::register_S3_method`](https://klmr.me/box/dev/reference/register_S3_method.md)

- [mod-hooks](https://klmr.me/box/dev/reference/mod-hooks.md)

## Interactive use

Functions for use in interactive sessions and for testing.

- [`box::help`](https://klmr.me/box/dev/reference/help.md)

- [`box::unload`](https://klmr.me/box/dev/reference/unload.md),
  [`box::reload`](https://klmr.me/box/dev/reference/unload.md),
  [`box::purge_cache`](https://klmr.me/box/dev/reference/unload.md)

- [`box::set_script_path`](https://klmr.me/box/dev/reference/script_path.md)

- [`box::script_path`](https://klmr.me/box/dev/reference/script_path.md),
  [`box::set_script_path`](https://klmr.me/box/dev/reference/script_path.md)

## See also

Useful links:

- <https://klmr.me/box/>

- <https://github.com/klmr/box>

- Report bugs at <https://github.com/klmr/box/issues>

## Author

**Maintainer**: Konrad Rudolph <konrad.rudolph@gmail.com>
([ORCID](https://orcid.org/0000-0002-9866-7051))

Authors:

- Konrad Rudolph <konrad.rudolph@gmail.com>
  ([ORCID](https://orcid.org/0000-0002-9866-7051))

Other contributors:

- Michael Schubert <mschu.dev@gmail.com>
  ([ORCID](https://orcid.org/0000-0002-6862-5221)) \[contributor\]

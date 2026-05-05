# Display module documentation

`box::help` displays help on a module’s objects and functions in much
the same way [`help`](https://rdrr.io/r/utils/help.html) does for
package contents.

## Usage

``` r
box::help(topic, help_type = getOption("help_type", "text"))
```

## Arguments

- topic:

  either the fully-qualified name of the object or function to get help
  for, in the format `module$function`; or a name that was exported and
  attached from an imported module or package.

- help_type:

  character string specifying the output format; currently, only
  `'text'` is supported.

## Value

`box::help` is called for its side effect when called directly from the
command prompt.

## Details

See the vignette at
[`vignette('box', 'box')`](https://klmr.me/box/articles/box.md) for more
information about displaying help for modules.

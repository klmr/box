# Helper functions for the help functionality

`help_topic_target` parses the expression being passed to the `help`
function call to find the innermost module subset expression in it.
`find_env` acts similarly to
[`find`](https://rdrr.io/r/utils/apropos.html), except that it looks in
the current environment’s parents rather than in the global environment
search list, it returns only one hit (or zero), and it returns the
environment rather than a character string. `call_help` invokes a
[`help()`](https://klmr.me/box/dev/reference/help.md) call expression
for a package help topic, finding the first `help` function definition,
ignoring the one from this package.

## Usage

``` r
help_topic_target(topic, caller)

find_env(name, caller)

call_help(call, caller)
```

## Arguments

- topic:

  the unevaluated expression passed to `help`.

- caller:

  the environment from which `help` was called.

- name:

  the name to look for.

- call:

  the patched `help` call expression.

## Value

`help_topic_target` returns a list of two elements containing the
innermost module of the `help` call, as well as the name of the object
that’s the subject of the `help` call. For `help(a$b$c$d)`, it returns
`list(c, quote(d))`.

Modules for R
=============

Summary
-------

This package provides an alternative mechanism of organising reusable code into
units, called “modules”. Its usage and organisation is reminiscent of Python’s.
It is designed so that normal R source files are automatically modules, and need
not be augmented by meta information or wrapped in order to be distributed, in
contrast to R packages.

Modules are loaded via the syntax

```splus
module = import(module)
```

Where `module` is the name of a module. Like in Python, modules can be grouped
together, so that a name of a module could be, e.g. `tools.strings`. This could
be used via

```splus
str = import(tools.strings)
```

This will import the code from a file with the name `tools/strings.R`, located
either under the local directory or at a predefined, configurable location.

Exported functions of the module could then be accessed via `str$func`:

```splus
some_string = 'Hello, World!'
upper = str$to_upper(some_string)
# => 'HELLO, WORLD!'
```

Notice that we’ve aliased the actual module name to `str` in user code.

Alternatively, modules can be imported into the global namespace:

```splus
import(tools.strings, attach = TRUE)
```

The module is then added to R’s `search()` vector (or equivalent) so that
functions can be accessed without qualifying the module’s imported name each
time.

R modules are normal R source files. However, `import` is different from
`source` in some crucial regards. It’s also crucially different from normal
packages. Please refer to the [comparison](#feature comparison) for details.

Feature comparison
------------------

### With source files (`source`)

Because of this package’s design, modules can directly replace `source`
statements in code; in most cases,

```splus
source('relative/path/file.R')
```

can be replaced by

```splus
import(relative.path.file, attach = TRUE)
```
– albeit with marked improvements:

* Module content is loaded into its own private environment, akin to setting the
  `local=TRUE` option. It thus avoids polluting the global environment.
* Loading happens in the module’s own directory, allowing the module to load
  local sources (the corresponding `source` option is `chdir=TRUE`).
* `import` uses a standardised, customisable search path to locate modules (but
  giving precedence to modules in the current directory), making it easy to
  reuse source files across projects without having to copy them around.
* Repeatedly `import`ing, even in different modules, loads the module only once.

### With packages (`library`)

Modules are conceived as a lightweight alternative to packages (see
[rationale](#design rationale)). As such, modules are generally intended to be
more lightweight than packages.

* Most importantly, modules often consist of single source code files.
* Modules do not need a `DESCRIPTION` file or similar.
* Modules offer more stringent protection against name clashes. While attaching
  to the R `search()` path is supported, it’s not the default, and (like in
  Python), it’s generally discouraged in favour of explicitly qualifying
  accesses to the module with the module name (or an alias).
* Changing a module does not necessitate a module reinstall, the changes are
  available directly to clients (and even to running sessions, via `reload`).
* Modules can be local to a project. This allows structuring projects
  internally, something that packages only allow at coarse level. In particular,
  modules can be *nested* as in Python to create hierarchies, and this is in
  fact encouraged.
* As of now, no documentation for functions is loaded for modules. This is
  currently the biggest “to do” item.
* As of now, there is no support for non-R code or dynamic libraries (but one
  may of course use facilities such as `dyn.load` and [Rcpp][] to include
  compiled code).

[Rcpp]: http://www.rcpp.org/

### With Python’s `import` mechanism

> TODO

Design rationale
----------------

> TODO
>
> * Why? Why replace packages (mention `devtools`)?
> * Why use identifier rather than character string as argument?
> * Why not *allow* character string, as `library` does?
> * Why not auto-define module reference in calling code, necessitating a
>   strictly redundant assignment?

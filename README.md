Modules for R
=============

Table of contents
-----------------

* [Summary](#summary)
* [Installation](#installation)
* [Usage](#usage)
* [Feature comparison](#feature-comparison)
* [Design rationale](#design-rationale)
* [To do](#to-do)


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

This will import the code from a file with the name `tools/strings.r`, located
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
packages. Please refer to the [comparison](#feature-comparison) for details.


Installation
------------

To install using [`devtools`](https://github.com/hadley/devtools), just type the
following command in R:

```splus
install_github('klmr/modules')
```


Usage
-----

Local, single-file modules can be used as-is: assuming you have a file called
`foo.r` in your current directory, execute

```splus
foo = import(foo)
```

in R to make its content accessible via a module, and use it via
`foo$function_name(…)`. Alternatively, you can use

```splus
import(foo, attach = TRUE)
```

but this form is usually discouraged since it clutters the global search path
(inside modules it’s fine because modules are isolated namespaces and don’t leak
their scope).

If you want to access a module in a non-local path, the cleanest way is to
create a central repository (e.g. at `~/.R/modules`) and to copy module source
files there. Then you can either set the environment variable `R_IMPORT_PATH`
or, inside R, `options('import.path')` in order for `import` to find modules
present there.

Nested modules (called “packages” in Python, but for obvious reasons this name
is not used for R modules) are directories (either local, or in the import
search path) which contain an `__init__.r` file. Assuming you have such a
module `foo`, inside which is a nested module `bar`, you can then make it
available in R via

```splus
foo = import(foo)     # Make available all of foo, or
bar = import(foo.bar) # Make available only bar
```

During module development, you can `reload` a module to reflect its changes
inside R, or `unload` it. In order to do this, you need to have assigned the
result of `import` to an identifier.

Feature comparison
------------------

### With source files (`source`)

Because of this package’s design, modules can directly replace `source`
statements in code; in most cases,

```splus
source('relative/path/file.r')
```

can be replaced by

```splus
import(relative.path.file, attach = TRUE)
```
– albeit with marked improvements:

* Module content is loaded into its own private environment, akin to setting the
  `local=TRUE` option. It thus avoids polluting the global environment.
* Since modules are environments, a module’s content can be listed easily via
  `ls(modulename)`, and R shells provide auto-completion when writing
  `modulename$` and pressing <kbd>Tab</kbd> repeatedly.
* Modules can be executed directly (via `Rscript module.r` or similar) or
  `import`ed. Unlike via `source`, a module *knows* when it’s being `import`ed,
  which allows code to be executed conditionally only when it is executed
  directly:

  ```splus
  if (is.null(module_name())) {
      …
  }
  ```

  This, of course, is similar to Python’s `if __name__ == '__main__': …`
  mechanism. `module_name` returns a module’s name. Module source files which
  are being executed directly don’t act as modules and hence have no name
  (`module_name()` is `NULL`).
* Loading happens in the module’s own directory, allowing the module to load
  local sources (the corresponding `source` option is `chdir=TRUE`).
* `import` uses a standardised, customisable search path to locate modules (but
  giving precedence to modules in the current directory), making it easy to
  reuse source files across projects without having to copy them around.
* Repeatedly `import`ing, even in different modules, loads the module only once.
  This makes it particularly well-suited for structuring projects into small,
  decomposable units. This project was mainly borne out of the frustration that
  is repeatedly `source`ing the same file, or alternatively having one “master
  header” file which includes all other source files.
* Modules can only export functions, not objects. This is a consequence of how R
  handles functions and objects, but it is a limitation that modules embrace to
  enforce a clean public interface.

### With packages (`library`)

Modules are conceived as a lightweight alternative to packages (see
[rationale](#design-rationale)). As such, modules are generally intended to be
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
* Control over exported and imported symbols is less fine-grained than for
  packages with namespace for now. This is intentional, since modules handle
  namespaces (via environments) more stringently than packages by default.
  However, this might still change in the future to allow more control.

[Rcpp]: http://www.rcpp.org/

### With Python’s `import` mechanism

> TODO


Design rationale
----------------

### Why? Why not use / write packages?

While using R for exploratory data analysis as well as writing more robust
analysis code, I have experienced the R mechanism of clumsily `source`ing lots
of files to be a big hindrance. In fact, just adding a few helper functions to
make using `source` less painful naturally evolved into an incomplete ad-hoc
implementation of modules.

The standard answer to this problem is “write a package”. But in the humble
opinion of this person, R packages fall short in several regards, which this
package (the irony is not lost on me) strives to rectify.

#### i) Effort

Writing packages incurs a non-trivial overhead. Packages need to live in their
own folder hierarchy (and, importantly, cannot be nested), they require the
specification of some meta information, a lot of which is simply irrelevant
unless there is an immediate interest in publishing the package (such as the
author name and contact, and licensing information). While it’s all right to
thus encourage publication, realistically most code, even if reused internally,
is never published.

Last but not least, packages, before they can be used in code, need to be
*built* and *installed*. And this needs to be repeated *every time* a single
line of code is changed in the package. This is fine when developing a package
in isolation; not so much when developing it in tandem with a bigger code base.

`devtools` improves this work flow, but, as a [commenter on Stack Overflow][so]
has pointed out,

> devtools […] reduces the packaging effort from X to X/5, but X/5 in R is still
> significant. In sensible interpreted languages X equals zero!

A direct consequence of this is that many people *do* end up `source`ing all
their code, and copying it between projects, and not putting their reusable code
into a package. At best this is a lost opportunity. At worst you struggle
keeping helper files between different projects in sync, which I’ve seen happen
a lot.

[so]: http://stackoverflow.com/a/15789538/1968

#### ii) Not hierarchical

Modular code often naturally forms recursive hierarchies. Most languages
recognise this and allow modules to be nested (just think of Python’s or Java’s
packages). R is the only widely used modern language (that I can think of) which
has a flat package hierarchy.

Allowing hierarchical nesting encourages users to organise project code into
small, reusable modules from the outset. Even if these modules never get reused,
they still improve the maintainability of the project.

#### iii) Low cohesion, tight coupling

R’s packaging mechanism encourages huge, monolithic packages chock full of
unrelated functions. CRAN has plenty of such packages. Without pointing fingers,
let me give, as an example, the otherwise tremendously helpful [agricolae][]
package, whose description reads

> Statistical Procedures for Agricultural Research

… I know projects which use this package because it includes a function to
generate a consensus tree via bootstrapping. The projects in question have no
relation whatsoever to agricultural research – and yet they resort to using a
package whose *name* hints at its purpose, simply because of low cohesion.

R’s packages fundamentally bias development towards [bad software
engineering practices][cohesion].

[agricolae]: http://cran.r-project.org/web/packages/agricolae/index.html
[cohesion]: http://en.wikipedia.org/wiki/Cohesion_(computer_science)

#### iv) Name clashes

R packages provide namespaces and a mechanism for shielding client code from
imports in the packages themselves. Nevertheless, there are situations where
name clashes occur, because not all packages use namespaces (correctly).
R 3.0.0 has allegedly solved this (by requiring use of namespaces) but I can
still reproducibly generate a name clash with at least one package.

### Why is the module name not passed as a string?

`import` mimics `library` here – more importantly, however, `import` accepts an
identifier because that is *fundamentally* what we want to convey. Module names
should be thought of not as strings (and even less as paths!) but as language
objects.

### Okay, but why not allow a string also?

`import` makes it fundamentally impossible to pass a module name via a variable.
Again, this is fully intentional. Allowing `import(name = 'module')` would be
trivially feasible. However, this goes explicitly against the intention of this
package to provide a uniform interface, and experience from other languages
(in the form of hard-coded library dependencies, module imports and headers)
shows that making the imported module modifiable via variables is not needed.

Incidentally, this also encourages the use of file names which resemble R
identifiers.

### Why do I manually need to assign the loaded module to a variable?

In other words, why does `import` force the user to write

```splus
module = import(module)
```

Where the `module` name is redundant, instead of

```splus
import(module)
```

With the latter call automatically defining the required variable in the calling
code? R definitely makes this possible (`reload` does it). However, several
reasons speak against it. It’s potentially destructive (in as much as it may
inadvertently overwrite an existing variable), and it makes the function rely
entirely on side-effects, something which R code should always be wary of. It
also makes it less obvious how to define an alias for the imported module in
user code. As it is, the user can simply alias a module by assigning it to a
different name, e.g. `m = import(module)`.

Granted, both `unload` and `reload` violate this. However, both are actually
*safe* because they only change the variable explicitly passed to them, and they
shouldn’t be used in most code anyway (their purpose is for use in interactive
sessions while developing modules).

### Why are nested names accessed via `$`?

> TODO / subject to change?


To do
-----

* Make S3 (and S4?) method lookup work.
* Parse and load attached documentation?
* Add argument `nonlocal` to override loading from working directory
* Add simple module installation mechanism (`install.gist` etc).
* Fix `unload` and `reload` to work with attached and multiply loaded modules
* Add argument `path` to `import` to temporarily override `import.path`.

[1]: https://github.com/klmr/modules/issues/1

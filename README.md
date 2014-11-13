![Logo](../../blob/images/r-modules.png?raw=true) Modules for R
===============================================================

[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/klmr/modules?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Table of contents
-----------------

* [Summary](#summary)
* [Installation](#installation)
* [Usage](#usage)
* [Feature comparison](#feature-comparison)
* [Design rationale](#design-rationale)


Summary
-------

This package provides an alternative mechanism of organising reusable code into
units, called “modules”. Its usage and organisation is reminiscent of Python’s.
It is designed so that normal R source files are automatically modules, and need
not be augmented by meta information or wrapped in order to be distributed, in
contrast to R packages.

Modules are loaded via the syntax

```r
module = import('module')
```

Where `module` is the name of a module. Like in Python, modules can be grouped
together in submodules, so that a name of a module could be, e.g.
`tools/strings`. This could be used via

```r
str = import('tools/strings')
```

This will import the code from a file with the name `tools/strings.r`, located
either under the local directory or at a predefined, configurable location.

Exported functions of the module could then be accessed via `str$func`:

```r
some_string = 'Hello, World!'
upper = str$to_upper(some_string)
# => 'HELLO, WORLD!'
```

Notice that we’ve aliased the actual module name to `str` in user code.

Alternatively, modules can be imported into the global namespace:

```r
import('tools/strings', attach = TRUE)
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

```r
devtools::install_github('klmr/modules')
```


Usage
-----

Local, single-file modules can be used as-is: assuming you have a file called
`foo.r` in your current directory, execute

```r
foo = import('foo')
# or: foo = import('./foo')
```

in R to make its content accessible via a module, and use it via
`foo$function_name(…)`. Alternatively, you can use

```r
import('foo', attach = TRUE)
```

But this form is usually discouraged at the file scope since it clutters the
global search path (although it’s worth noting that modules are isolated
namespaced and don’t leak their scope).

If you want to access a module in a non-local path, the cleanest way is to
create a central repository (e.g. at `~/.R/modules`) and to copy module source
files there. Then you can either set the environment variable `R_IMPORT_PATH`
or, inside R, `options('import.path')` in order for `import` to find modules
present there.

Nested modules (called “packages” in Python, but for obvious reasons this name
is not used for R modules) are directories (either local, or in the import
search path) which optionally contain an `__init__.r` file. Assuming you have
such a module `foo`, inside which is a submodule `bar`, you can then make it
available in R via

```r
foo = import('foo')     # Make available foo, or
bar = import('foo/bar') # Make available only foo/bar
```

During module development, you can `reload` a module to reflect its changes
inside R, or `unload` it. In order to do this, you need to have assigned the
result of `import` to an identifier.

Feature comparison
------------------

### With source files (`source`)

Because of this package’s design, modules can directly replace `source`
statements in code; in most cases,

```r
source('relative/path/file.r')
```

can be replaced by

```r
import('relative/path/file', attach = TRUE)
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

  ```r
  if (is.null(module_name())) {
      …
  }
  ```

  This is of course similar to Python’s `if __name__ == '__main__': …`
  mechanism. `module_name` returns a module’s name. Module source files which
  are being executed directly don’t act as modules and hence have no name
  (`module_name()` is `NULL`).
* Modules can import other modules relative to their own path, without having to
  `chdir` to the module’s path (similar to the `source` option `chdir=TRUE`, but
  preserving `getwd()`).
* `import` uses a standardised, customisable search path to locate modules (but
  giving precedence to modules in the current directory), making it easy to
  reuse source files across projects without having to copy them around.
* Repeatedly `import`ing, even in different modules, loads the module only once.
  This makes it particularly well-suited for structuring projects into small,
  decomposable units. This project was mainly borne out of the frustration that
  is repeatedly `source`ing the same file, or alternatively having one “master
  header” file which includes all other source files.
* Doc comments inside a module source file are parsed during `import`, and
  interactive help on module contents is subsequently available via the usual
  mechanisms (e.g. `?mod$fun`).

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
* As of now, there is no support for non-R code or dynamic libraries (but one
  may of course use facilities such as `dyn.load` and [Rcpp][] to include
  compiled code).
* Control over exported and imported symbols is less fine-grained than for
  packages with namespace for now. This is intentional, since modules handle
  namespaces (via environments) more stringently than packages by default.
  However, this might still change in the future to allow more control.

[Rcpp]: http://www.rcpp.org/

### With Python’s `import` mechanism

R modules are heavily inspired by Python modules, but embedded in R syntax.

* There is one general form of the `import` function, corresponding to
  <code>import <em>modname</em></code> in Python. Arguments can be used to
  emulate the other forms: <code>import(<em>x</em>, attach = TRUE)</code>
  loosely corresponds to <code>from <em>x</em> import \*</code>.
  <code>import(<em>x</em>, attach = c('foo', 'bar'))</code> corresponds to
  <code>from <em>x</em> import foo, bar</code>.

* Like in Python, imports are absolute by default. This means that if there are
  two modules of the same name, one in the global search path and one in the
  local directory, `import`ing that module will resolve to the one in the global
  search path, and in order to import the local module instead, the user has to
  specify a relative path: <code>import('./<em>modname</em>')</code>. Unlike in
  Python, modules can always be specified as relative imports, not only for
  submodules.

* When specifying `attach = TRUE`, names of the `import`ed module are made
  available directly in the calling scope, but unlike in Python they are not
  *copied* into that scope, so local names may shadow imported names.

* As a consequence of this, modules export functions and objects they define,
  but they do not export symbols they themselves import: if a module `a`
  contains `import('b', attach = TRUE)`, none of the symbols from `b` will be
  visible for any code importing `a`. Where this is not the desired behaviour,
  users can use the `export_submodule` function instead of `import`.

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

### Why do I manually need to assign the loaded module to a variable?

In other words, why does `import` force the user to write

```r
module = import('module')
```

Where the `module` name is redundant, instead of

```r
import('module')
```

With the latter call automatically defining the required variable in the calling
code? R definitely makes this possible (`reload` does it). However, several
reasons speak against it. It’s potentially destructive (in as much as it may
inadvertently overwrite an existing variable), and it makes the function rely
entirely on side-effects, something which R code should always be wary of. It
also makes it less obvious how to define an alias for the imported module in
user code. As it is, the user can simply alias a module by assigning it to a
different name, e.g. `m = import('module')`.

Granted, both `unload` and `reload` violate this. However, both are actually
*safe* because they only change the variable explicitly passed to them, and they
shouldn’t be used in most code anyway (their purpose is for use in interactive
sessions while developing modules).

### Why are nested names accessed via `$`?

Module objects are environments and, as such, allow any form of access that
normal environments allow. This notably includes access of objects via the `$`
operator. This differs from R packages, where objects can be explicitly
addressed with the `package::object` syntax. For now, this syntax is not
supported for modules because it is ambiguous when a module name shadows a
package.

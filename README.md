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
packages. Please refer to the [comparison](#feature-comparison) for details.

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
  This makes it particularly well-suited for structuring projects into small,
  decomposable units. This project was mainly borne out of the frustration that
  is repeatedly `source`ing the same file, or alternatively having one “master
  header” file which includes all other source files.

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

[Rcpp]: http://www.rcpp.org/

### With Python’s `import` mechanism

> TODO

Design rationale
----------------

### Why? Why not use / write packages?

While using R for exploratory data analysis as well as writing more robust
analysis code, I have experienced the R mechanism of clumsily `source`ing lots
of files to be a big hindrance.

The standard answer to this dilemma is “write a package”. But in the humble
opinion of this person, R packages fall short in several regards, which this
package (the irony is not lost on me) strives to rectify.

#### Effort

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

#### Not hierarchical

> TODO
> (All other languages do it and it’s very helpful for organisation)

> (It also improves project organisation and encourages using lots of small
> modules inside a project, encouraging writing reusable code from the outset)

#### Low cohesion, tight coupling

R’s packaging mechanism encourages huge, monolithic packages chock full of
unrelated functions. CRAN has plenty of such packages. Without pointing fingers,
let me give, as an example, the otherwise tremendously helpful [agricolae][]
package, whose description reads

> Statistical Procedures for Agricultural Research

… I know code which uses this package because it includes a function to generate
a consensus tree via bootstrapping. The code in question has no relation
whatsoever to agricultural research.

R’s packages fundamentally bias development towards [bad software
engineering practices][cohesion].

[so]: http://stackoverflow.com/a/15789538/1968
[agricolae]: http://cran.r-project.org/web/packages/agricolae/index.html
[cohesion]: http://en.wikipedia.org/wiki/Cohesion_(computer_science)

### Name clashes

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

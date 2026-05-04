# Similar packages

The need for tools to make R code more modular, and to improve code
reuse, is demonstrated by the wealth of related packages that have
sprung up over the years. Many of them have objectives similar to ‘box’,
although they vary wildly in how they approach their common goal, and
not all objectives are shared. In the following I’ve listed the related
R packages that I know of. The descriptions are (mostly) copied from the
respective package metadata, and the interested reader is invited to
consult the original documentation.

The list is intended to be a fairly exhaustive — so if you find a
missing package please let me know.

## Tools for writing modular code

- ‘**[modules](https://cran.r-project.org/package=modules)**’ (no
  relation to the predecessor of ‘box’, also called ‘modules’): Provides
  modules as an organizational unit for source code. Modules enforce to
  be more rigorous when defining dependencies and have a local search
  path. They can be used as a sub unit within packages or in scripts.

- ‘[trinker/**pysty**](https://trinkerrstuff.wordpress.com/2018/02/22/minimal-explicit-python-style-package-loading-for-r/)’:
  ‘Python’ style packages importing using the common forms of:
  `import PACKAGE`, `import PACKAGE as ALIAS`, or
  `from PACKAGE import FUN1, FUN2, FUN_N`.

- ‘[**Shiny**’
  modules](https://shiny.rstudio.com/articles/modules.html): ‘Shiny’
  modules address the namespacing problem in Shiny UI and server logic,
  adding a level of abstraction beyond functions.

- ‘[Novartis/**tidymodules**](https://opensource.nibr.com/tidymodules/)’:
  ‘tidymodules’ offers a robust framework for developing ‘Shiny’ modules
  based on R6 classes which should facilitates inter-modules
  communication.

## Tools for loading code

The packages listed above also provide means for loading code; however,
I won’t replicate them here. Some of the tools below have subsequently
also gained capabilities for authoring modular code, but since their
initial and primary purpose was *loading* code, they’re instead listed
below.

- ‘**[import](https://cran.r-project.org/package=import)**’: Alternative
  mechanism for importing objects from packages and R modules. The
  syntax allows for importing multiple objects with a single command in
  an expressive way. The import package bridges some of the gap between
  using library (or require) and direct (single-object) imports.
  Furthermore the imported objects are not placed in the current
  environment.

- ‘**[conflicted](https://conflicted.r-lib.org/)**’: R’s default
  conflict management system gives the most recently loaded package
  precedence. This can make it hard to detect conflicts, particularly
  when they arise because a package update creates ambiguity that did
  not previously exist. ‘conflicted’ takes a different approach, making
  every conflict an error and forcing you to choose which function to
  use.

- ‘**[pacman](http://trinker.github.io/pacman/)**’: Tools to more
  conveniently perform tasks associated with add-on packages. pacman
  conveniently wraps library and package related functions and names
  them in an intuitive and consistent fashion. It seeks to combine
  functionality from lower level functions which can speed up workflow.

- ‘[jonocarroll/**importAs**](https://jonocarroll.github.io/importAs/)’:
  Import namespaces as shorthand symbols rather than full package names,
  in a python-esque fashion.

- ‘[**needs**](https://cran.r-project.org/package=needs)’: A simple
  function for easier package loading and auto-installation.

- ‘[**importar**](https://cran.r-project.org/package=importar)’: Enables
  ‘Python’-like importing/loading of packages or functions with aliasing
  to prevent namespace conflicts.

- [**xfun**::pkg_attach()](https://yihui.org/en/2018/09/xfun-pkg-attach/):
  A vectorized version of
  [`library()`](https://rdrr.io/r/base/library.html)

## Tools for organising code

- ‘**[RSuite](https://cran.r-project.org/package=RSuite)**’: Supports
  safe and reproducible solutions development in R. It will help you
  with environment separation per project, dependency management, local
  packages creation and preparing deployment packs for your solutions.
  (Archived as of 2026-05-04)

- ‘**[mvbutils](https://cran.r-project.org/package=mvbutils)**’:
  Hierarchical workspace tree, code editing and backup, easy package
  prep, editing of packages while loaded, per-object lazy-loading, easy
  documentation, macro functions, and miscellaneous utilities.

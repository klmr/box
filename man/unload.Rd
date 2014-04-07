\name{unload}
\alias{unload}
\title{Unload a given module}
\usage{
unload(module)
}
\arguments{
  \item{module}{reference to the module which should be
  unloaded}
}
\description{
Unset the module variable that is being passed as a
parameter, and remove the loaded module from cache.
}
\note{
Any other references to the loaded modules remain
unchanged, and will still work. However, subsequently
importing the module again will reload its source files,
which would not have happened without \code{unload}.
Unloading modules is primarily useful for testing during
development, and should not be used in production code.

\code{unload} does not currently detach environments.
}
\seealso{
\code{import}

\code{reload}
}


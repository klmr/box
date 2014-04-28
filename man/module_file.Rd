\name{module_file}
\alias{module_file}
\title{Find the full file names of files in modules}
\usage{
module_file(..., module = parent.frame(), mustWork = FALSE)
}
\arguments{
  \item{...}{character vectors of files or subdirectories
  inside a module; if none is given, returns the root
  directory of the module}

  \item{module}{a module environment (default: current
  module)}

  \item{mustWork}{logical; if \code{TRUE}, an error is
  raised if the given files do not match existing files.}
}
\value{
A character vector containing the absolute paths to the
files specified in \code{...}, or an empty string,
\code{''}, if no file was found (unless \code{mustWork =
TRUE} was specified).
}
\description{
Find the full file names of files in modules
}
\note{
If called from outside a module, the current working
directory is used.
}
\seealso{
\code{base::system.file}
}


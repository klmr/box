source('~/.Rprofile')

# For testing existing modules:
options(import.path = '~/Projects/R')
# R sets wrong path on OS X 10.9 (Mavericks)
Sys.setenv(TAR = '/usr/bin/tar')

# `utils` package should already be loaded by now but isn’t. Do it manually.
# (Details: http://stackoverflow.com/q/14670217/1968)
library(utils)
library(devtools)
dev_mode()
load_all()

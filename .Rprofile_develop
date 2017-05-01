source('~/.Rprofile')

# For testing existing modules:
options(import.path = 'inst/tests/modules')
# R sets wrong path on OS X 10.9 (Mavericks)
Sys.setenv(TAR = '/usr/bin/tar')

source('printenv.r')

library(utils)
library(devtools)
dev_mode(TRUE)
load_all()

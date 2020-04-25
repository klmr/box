objects = 'hello'

# Change working directory so R finds the Makevars.
oldwd = getwd()
on.exit(setwd(oldwd))
setwd(xyz::file())

result = system2('R', c('CMD', 'SHLIB', paste0(objects, '.c')))
stopifnot(result == 0L)

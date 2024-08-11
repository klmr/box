build_shared_lib = function (object_names) {
    # Change working directory so R finds the Makevars.
    old_dir = setwd(box::file())
    on.exit(setwd(old_dir))
    exitcode = system2('R', c('CMD', 'SHLIB', paste0(object_names, '.c')))
    stopifnot(exitcode == 0L)
}

build_shared_lib('hello')

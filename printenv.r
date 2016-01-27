printenv = function (env = parent.frame()) {
    frame = 1
    while (! identical(env, baseenv())) {
        name = environmentName(env)
        name_display = sprintf('<environment: %s>', name)
        default_display = capture.output(env)[1]

        cat(default_display)
        if (name_display != default_display) {
            if (frame < sys.nframe() && ! is.null((fn = sys.function(frame)))) {
                fn_env = environment(fn)
                # Inside a function, print function name.
                name = function_name(fn, fn_env)
            }
            cat(sprintf(' (%s)', name))
        }
        cat('\n')
        env = parent.env(env)
        frame = frame + 1
    }
    cat('<environment: base>\n')
}

function_name = function (definition, envir) {
    candidates = as.character(lsf.str(envir))
    mod_name = module_name(envir)
    for (candidate in candidates)
        if (identical(get(candidate, envir, mode = 'function'), definition))
            return(paste(c(mod_name, candidate), collapse = '$'))
    warning('No candidate function found, probably a bug')
}

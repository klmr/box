printenv = function (env = parent.frame()) {
    while (! identical(env, baseenv())) {
        name = environmentName(env)
        name_display = sprintf('<environment: %s>', name)
        default_display = capture.output(env)[1]

        cat(default_display)
        if (name_display != default_display)
            cat(sprintf(' (%s)', name))
        cat('\n')
        env = parent.env(env)
    }
    cat('<environment: base>\n')
}

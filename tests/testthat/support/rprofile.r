# Set up R so that R called from a unit test finds everything in order.

local({
    # First, find the original user profile, if any. The environment variable is
    # set by the test code calling R to the value of `R_PROFILE_USER`.

    user_profile = Sys.getenv('R_ORIGINAL_PROFILE_USER')
    if (user_profile == '') {
        user_profile = if (file.exists('.Rprofile')) '.Rprofile' else '~/.Rprofile'
    }

    # Next, ensure that the ‘box’ package that’s loaded is the source version
    # we’re currently testing, rather than something loaded by the user
    # configuration.

    unloadNamespace('box')
    devtools::load_all(Sys.getenv('BOX_TESTING_BASEDIR'), quiet = TRUE, export_all = FALSE)
    detach('package:box')

    # … and load the original user profile, if it exists.

    if (file.exists(user_profile)) {
        sys.source(user_profile, envir = .GlobalEnv)
    }

    old_first = get0('.First', envir = .GlobalEnv, ifnotfound = function () {})
    .GlobalEnv$.First = function () {
        old_first()
        # This is required by `interactive_r` to verify that invocation succeeded.
        options(prompt = '> ', continue = '+ ')
    }
})

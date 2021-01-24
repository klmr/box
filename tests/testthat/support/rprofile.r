# Set up R so that R called from a unit test finds everything in order.

# First, load the original user profile, if any. The environment variable is
# set by the test code calling R to the value of `R_PROFILE_USER`.

user_profile = Sys.getenv('R_ORIGINAL_PROFILE_USER', '~/.Rprofile')
if (identical(user_profile, '')) {
    user_profile = '~/.Rprofile'
}

if (file.exists(user_profile)) {
    source(user_profile)
}

# Next, ensure that the ‘box’ package that’s loaded is the source version we’re
# currently testing, rather than something loaded by the user configuration.

unloadNamespace('box')
devtools::load_all(quiet = TRUE)

# This is required by `interactive_r` to verify that invocation succeeded.

options(prompt = '> ')

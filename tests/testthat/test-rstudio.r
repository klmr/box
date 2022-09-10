context('RStudio')

with_mock_rstudio = function (expr) {
    Sys.setenv(RSTUDIO = "1")

    old_gui = .Platform$GUI
    unlockBinding('.Platform', .BaseNamespaceEnv)
    .BaseNamespaceEnv$.Platform$GUI = 'RStudio'
    Sys.unsetenv('TESTTHAT')

    on.exit({
        Sys.unsetenv("RSTUDIO")
        .BaseNamespaceEnv$.Platform$GUI = old_gui
        lockBinding('.Platform', .BaseNamespaceEnv)
        Sys.setenv(TESTTHAT = 'true')
    })

    expr
}

with_mock_rstudio_tools_path = function (path, expr) {
    rstudio_tools_env = new.env()
    local(envir = rstudio_tools_env, {
        .rs.api.getActiveDocumentContext = function () { # nolint
            list(
                path = path,
                contents = '',
                selection = list(list(range = rep(1L, 4L), text = ''))
            )
        }
        .rs.api.versionInfo = function () list()
    })
    on.exit(detach('tools:rstudio'))
    attach(rstudio_tools_env, name = 'tools:rstudio')

    expr
}

test_that('Path of active file in RStudio is found without ‘rstudioapi’', {
    skip_on_ci()
    skip_on_cran()
    # Assume that we cannot edit package library path on other systems.
    skip_outside_source_repos()

    pkg_path = dirname(dirname(attr(suppressWarnings(packageDescription('rstudioapi')), 'file')))
    tmp_path = paste0(pkg_path, '-x')

    unloadNamespace('rstudioapi')
    expect_true(file.rename(pkg_path, tmp_path))
    on.exit(file.rename(tmp_path, pkg_path))

    file_path = with_mock_rstudio({
        with_mock_rstudio_tools_path('/rstudio/test.r', box::file())
    })

    expect_paths_equal(file_path, '/rstudio')
    expect_false(isNamespaceLoaded('rstudioapi'))
})

test_that('Path of active file in RStudio is found with ‘rstudioapi’', {
    skip_on_cran()
    skip_if_not_installed('rstudioapi')

    file_path = with_mock_rstudio({
        with_mock_rstudio_tools_path('/rstudio/test.r', box::file())
    })

    expect_paths_equal(file_path, '/rstudio')
    expect_true(isNamespaceLoaded('rstudioapi'))
})

app = box::file('shiny-app')
tryCatch(
    shiny::runApp(app, launch.browser = FALSE),
    error = invisible
)

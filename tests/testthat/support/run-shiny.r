app = box::file('shiny-app')
tryCatch(
    suppressMessages(shiny::runApp(app, launch.browser = FALSE)),
    error = invisible
)

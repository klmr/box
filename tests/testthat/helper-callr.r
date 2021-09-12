r_cmdline = function (cmd, ...) {
    skip_on_os('windows')
    # Some of the script tests fail on CRAN and, lacking stack traces, it’s
    # simply impossible to debug this. So we disable them.
    skip_on_cran()

    in_tests = grepl('tests/testthat$', getwd())
    rprofile = file.path(
        if (in_tests) '.' else 'tests/testthat',
        'support', 'rprofile.r'
    )
    args = c('--no-save', '--no-restore', ...)
    # Unset `TESTTHAT` since otherwise ‘box’ thinks that tests are being run
    # from inside ‘testthat’, and fudges the local search path.
    sprintf(
        'TESTTHAT= R_ORIGINAL_PROFILE_USER="$R_PROFILE_USER" R_PROFILE_USER="%s" %s %s',
        rprofile, cmd, paste(shQuote(args), collapse = ' ')
    )
}

rcmd = function (script_path) {
    output_file = tempfile(fileext = '.rout')
    on.exit(unlink(output_file))
    cmd = r_cmdline(
        '"$R_HOME/bin/R" CMD BATCH',
        '--slave',
        '--no-timing',
        script_path,
        output_file
    )
    system(cmd)
    readLines(output_file)
}

rscript = function (script_path) {
    cmd = r_cmdline('"$R_HOME/bin/Rscript"', '--slave', script_path)
    p = pipe(cmd)
    on.exit(close(p))
    readLines(p)
}

interactive_r = function (script_path, text, code) {
    cmd = r_cmdline('"$R_HOME/bin/R"', '--interactive')
    output_file = tempfile(fileext = '.rout')
    on.exit(unlink(output_file))

    text = if (! missing(script_path)) {
        readLines(script_path)
    } else if (! missing(code)) {
        deparse(substitute(code), backtick = TRUE)
    } else if (! missing(text)) {
        text
    } else {
        stop('Missing argument')
    }

    local({
        p = pipe(paste(cmd, '>', output_file), 'w')
        on.exit(close(p))
        writeLines(text, p)
        writeLines('interactive()', p)
    })

    result = readLines(output_file)

    strip_ansi_escapes = function (str) {
        # Only support CSI Select Graphic Rendition for now. This is necessary
        # to guard against R packages such as ‹colorout›.
        gsub('\033\\[(\\d+(;\\d+)*)?m', '', str)
    }

    check_line = function (which, expected) {
        # Separate check to generate only one assertion, and only if needed.
        if (! identical(strip_ansi_escapes(result[which]), expected)) {
            expect_identical(
                strip_ansi_escapes(result[which]), expected,
                label = sprintf('"%s"', result[which]),
                info = 'interactive_r'
            )
        }
    }

    # Ensure that code was actually run interactively.
    end = length(result)
    check_line(end - 2, '> interactive()')
    check_line(end - 1, '[1] TRUE')
    check_line(end, '> ')
    result[1 : (end - 3)]
}

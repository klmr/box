r_cmdline = function (cmd, args = '') {
    in_tests = grepl('tests/testthat$', getwd())
    rprofile = file.path(if (in_tests) '.' else 'tests/testthat', 'support', 'rprofile.r')
    args = c('--no-save', '--no-restore', args)
    sprintf('R_ORIGINAL_PROFILE_USER="$R_PROFILE_USER" R_PROFILE_USER="%s" %s %s',
            rprofile, cmd, paste(args, collapse = ' '))
}

rcmd = function (script_path) {
    cmd = r_cmdline('R CMD BATCH', c('--slave', '--no-timing'))
    output_file = tempfile(fileext = '.rout')
    on.exit(unlink(output_file))
    system(paste(cmd, script_path, output_file))
    readLines(output_file)
}

rscript = function (script_path) {
    cmd = r_cmdline('Rscript', '--slave')
    p = pipe(paste(cmd, script_path))
    on.exit(close(p))
    readLines(p)
}

interactive_r = function (script_path, text, code) {
    cmd = r_cmdline('R --interactive')
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
            expect_identical(strip_ansi_escapes(result[which]), expected,
                             label = sprintf('"%s"', result[which]),
                             info = 'interactive_r')
        }
    }

    # Ensure that code was actually run interactively.
    end = length(result)
    check_line(end - 2, '> interactive()')
    check_line(end - 1, '[1] TRUE')
    check_line(end, '> ')
    result[1 : (end - 3)]
}

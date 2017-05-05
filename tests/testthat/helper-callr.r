rcmd = function (script_path) {
    cmd = 'R CMD BATCH --slave --vanilla --no-restore --no-save --no-timing'
    output_file = 'output.rout'
    on.exit(unlink(output_file))
    system(paste(cmd, script_path, output_file))
    readLines(output_file)
}

rscript = function (script_path) {
    cmd = 'Rscript --slave --vanilla --no-restore --no-save'
    p = pipe(paste(cmd, script_path))
    on.exit(close(p))
    readLines(p)
}

interactive_r = function (script_path, text) {
    cmd = 'R --vanilla --interactive'
    output_file = tempfile(fileext = '.rout')
    on.exit(unlink(output_file))

    if (! missing(script_path))
        text = readLines(script_path)

    local({
        p = pipe(paste(cmd, '>', output_file), 'w')
        on.exit(close(p))
        writeLines(text, p)
        writeLines('interactive()', p)
    })

    result = readLines(output_file)

    check_line = function (which, expected)
        if (! identical(result[which], expected))
            stop('Unexpected value ', sQuote(result[which]), ', expected ',
                 sQuote(expected), ' in `interactive_r`')

    # Ensure that code was actually run interactively.
    end = length(result)
    check_line(end - 2, '> interactive()')
    check_line(end - 1, '[1] TRUE')
    check_line(end, '> ')
    result[1 : (end - 3)]
}

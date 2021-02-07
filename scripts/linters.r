# Some of the functions below are no longer exported despite the ‘lintr’
# vignette implying that they can/should be used (e.g. `ids_with_tokens`).
# So we just attach the entire namespace.
attach(asNamespace('lintr'), warn.conflicts = FALSE)

arrow_assignment_linter = function (source_file) {
    lapply(
        ids_with_token(source_file, 'LEFT_ASSIGN'),
        function (id) {
            parsed = with_id(source_file, id)
            if (parsed$text != '<<-') {
                Lint(
                    filename = source_file$filename,
                    line_number = parsed$line1,
                    column_number = parsed$col1,
                    type = "style",
                    message = "Use =, not <-, for assignment.",
                    line = source_file$lines[as.character(parsed$line1)],
                    linter = "assignment_linter"
                )
            }
        }
    )
}

double_quotes_linter = function (source_file) {
    re = rex::rex(start, '"', any_non_single_quotes, '"', end)

    lapply(
        ids_with_token(source_file, 'STR_CONST'),
        function(id) {
            parsed = with_id(source_file, id)
            if (rex::re_matches(parsed$text, re)) {
                Lint(
                    filename = source_file$filename,
                    line_number = parsed$line1,
                    column_number = parsed$col1,
                    type = "style",
                    message = "Only use single quotes.",
                    line = source_file$lines[as.character(parsed$line1)],
                    ranges = list(c(parsed$col1, parsed$col2)),
                    linter = "single_quotes_linter"
                )
            }
        }
    )
}

s3_object_length_linter = function (length = 30L) {
    make_object_linter(
        function (source_file, token) {
            parts = stringr::str_split(token, '\\.', 2L)[[1L]]
            if (any(nchar(parts) > length)) {
                object_lint(
                    source_file, token,
                    paste('Variable and function names should not be longer than', length, 'characters.'),
                    'object_length_linter'
                )
            }
        }
    )
}

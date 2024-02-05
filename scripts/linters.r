arrow_assignment_linter = function () {
    lintr::Linter(\(source_file) {
        lapply(
            lintr::ids_with_token(source_file, 'LEFT_ASSIGN'),
            \(id) {
                parsed = lintr::with_id(source_file, id)
                if (parsed$text != '<<-') {
                    lintr::Lint(
                        filename = source_file$filename,
                        line_number = parsed$line1,
                        column_number = parsed$col1,
                        type = 'style',
                        message = 'Use =, not <-, for assignment.',
                        line = source_file$lines[as.character(parsed$line1)],
                        linter = 'assignment_linter'
                    )
                }
            }
        )
    })
}

function_definition_linter = function () {
    bad_line_fun_xpath = '(//FUNCTION | //OP-LAMBDA)[@line1 != following-sibling::OP-LEFT-PAREN/@line1]'
    bad_line_call_xpath = '//SYMBOL_FUNCTION_CALL[@line1 != parent::expr/following-sibling::OP-LEFT-PAREN/@line1]'
    bad_col_fun_xpath = '//FUNCTION[
    @line1 = following-sibling::OP-LEFT-PAREN/@line1
    and @col2 != following-sibling::OP-LEFT-PAREN/@col1 - 2
    ]'
    bad_col_call_xpath = '//SYMBOL_FUNCTION_CALL[
    line1 = parent::expr/following-sibling::OP-LEFT-PAREN/@line1
    and @col2 != parent::expr/following-sibling::OP-LEFT-PAREN/@col1 - 1
    ]'

    lintr::Linter(\(source_expression) {
        if (! lintr::is_lint_level(source_expression, 'expression')) {
            return(list())
        }

        xml = source_expression$xml_parsed_content

        bad_line_fun_exprs = xml2::xml_find_all(xml, bad_line_fun_xpath)
        bad_line_fun_lints = lintr::xml_nodes_to_lints(
            bad_line_fun_exprs,
            source_expression = source_expression,
            lint_message = 'Left parenthesis should be on the same line as the \'function\' symbol.'
        )

        bad_line_call_exprs = xml2::xml_find_all(xml, bad_line_call_xpath)
        bad_line_call_lints = lintr::xml_nodes_to_lints(
            bad_line_call_exprs,
            source_expression = source_expression,
            lint_message = 'Left parenthesis should be on the same line as the function\'s symbol.'
        )

        bad_col_fun_exprs = xml2::xml_find_all(xml, bad_col_fun_xpath)
        bad_col_fun_lints = lintr::xml_nodes_to_lints(
            bad_col_fun_exprs,
            source_expression = source_expression,
            lint_message = 'Add spaces before the left parenthesis in a function definition.',
            range_start_xpath = 'number(./@col2 + 1)',
            range_end_xpath = 'number(./following-sibling::OP-LEFT-PAREN/@col1)'
        )

        bad_col_call_exprs = xml2::xml_find_all(xml, bad_col_call_xpath)
        bad_col_call_lints = lintr::xml_nodes_to_lints(
            bad_col_call_exprs,
            source_expression = source_expression,
            lint_message = 'Remove spaces before the left parenthesis in a function call.',
            range_start_xpath = 'number(./@col2 + 1)',
            range_end_xpath = 'number(./parent::expr/following-sibling::OP-LEFT-PAREN/@col1 - 1)'
        )

        c(bad_line_fun_lints, bad_line_call_lints, bad_col_fun_lints, bad_col_call_lints)
    })
}

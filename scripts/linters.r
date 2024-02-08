arrow_assignment_linter = function () {
    xpath = '//LEFT_ASSIGN | //RIGHT_ASSIGN'
    lint_message_fmt = 'Use =, not %s, for assignment.'

    lintr::Linter(\(source_expression) {
        if (! lintr::is_lint_level(source_expression, 'expression')) {
            return(list())
        }

        xml = source_expression$xml_parsed_content
        bad_expr = xml2::xml_find_all(xml, xpath)

        if (length(bad_expr) == 0L) {
            return(list())
        }

        operator = xml2::xml_text(bad_expr)

        lint_message = sprintf(lint_message_fmt, operator)
        lintr::xml_nodes_to_lints(bad_expr, source_expression, lint_message, type = 'style')
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

simple_object_length_linter = function (length = 30L) {
    # Copied with modifications from the ‘lintr’ source.
    object_name_xpath = local({
        xp_assignment_target = paste0(
            'not(preceding-sibling::OP-DOLLAR)',
            'and ancestor::expr[',
            '  following-sibling::LEFT_ASSIGN',
            '  or preceding-sibling::RIGHT_ASSIGN',
            '  or following-sibling::EQ_ASSIGN',
            ']',
            'and not(ancestor::expr[',
            '  preceding-sibling::OP-LEFT-BRACKET',
            '  or preceding-sibling::LBB',
            '])'
        )

        glue::glue('
            //SYMBOL[ {xp_assignment_target} ]
            |  //STR_CONST[ {xp_assignment_target} ]
            |  //SYMBOL_FORMALS
            '
        )
    })

    lint_message = glue::glue('Variable and function names should not be longer than {length} characters.')

    lintr::Linter(\(source_expression) {
        if (! lintr::is_lint_level(source_expression, 'file')) {
            return(list())
        }

        xml = source_expression$full_xml_parsed_content
        assignments = xml2::xml_find_all(xml, object_name_xpath)

        strip_names = function (x) {
            # The order of these matters!
            sub('^\\.', '', sub('^%.*%$', '\\1', sub('<-$', '', x)))
        }

        # Retrieve assigned name
        names = strip_names(xml2::xml_text(assignments))

        # Remove generic function names from generic implementations
        # This only lints S3 implementations if the class names are too long, still lints generics if they are too long.
        nms_stripped = sub('^.*\\.', '', names)
        too_long = nchar(nms_stripped) > length

        lintr::xml_nodes_to_lints(
            assignments[too_long],
            source_expression = source_expression,
            lint_message = lint_message,
            type = 'style'
        )
    })
}

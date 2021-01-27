context('interactive')

skip_outside_source_repos()

play_back_results = function (record_events, onto) {
    for (event in record_events) {
        switch(
            event$type,
            start_test = onto$start_test(event$context, event$test),
            add_result = onto$add_result(event$context, event$test, event$result),
            end_test = onto$end_test(event$context, event$test)
        )
    }
}

interactive_r(code = {
    library(testthat)
    devtools::load_all()

    RecordReporter = R6::R6Class('RecordReporter', inherit = Reporter,
        public = list(
            events = NULL,

            initialize = function () {
                super$initialize()
                self$events = testthat:::Stack$new()
            },

            start_test = function (context, test) {
                self$events$push(list(type = 'start_test', context = context, test = test))
            },

            add_result = function (context, test, result) {
                self$events$push(list(type = 'add_result', context = context, test = test, result = result))
            },

            end_test = function (context, test) {
                self$events$push(list(type = 'end_test', context = context, test = test))
            },

            get_events = function () {
                self$events$as_list()
            }
        )
    )

    record = RecordReporter$new()
    tryCatch(
        test_file('test-basic.r', reporter = record),
        finally = saveRDS(record$get_events(), 'test_results.rds')
    )
})

record_events = readRDS('test_results.rds')
unlink('test_results.rds')
play_back_results(record_events, get_reporter())

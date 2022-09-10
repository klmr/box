#' Set the base path of the script
#'
#' \code{box::set_script_path(path)} explicitly tells \pkg{box} the path of a
#' given script from which it is called; \code{box::script_path()} returns the
#' previously set path.
#' @usage \special{box::set_script_path(path)}
#' @param path character string containing the relative or absolute path to the
#' currently executing \R code file, or \code{NULL} to reset the path.
#' @return Both \code{box::script_path} and \code{box::set_script_path} return
#' the previously set script path, or \code{NULL} if none was explicitly set.
#' \code{box::set_script_path} returns its value invisibly.
#'
#' @details
#' \pkg{box} needs to know the base path of the topmost calling \R context (i.e.
#' the script) to find relative import locations. In most cases, \pkg{box} can
#' figure the path out automatically. However, in some cases third-party
#' packages load code in a way in which \pkg{box} cannot find the correct path
#' of the script any more. \code{box::set_script_path} can be used in these
#' cases to set the path of the currently executing \R script manually.
#'
#' @note
#' \pkg{box} \emph{should} be able to figure out the script path automatically.
#' Using \code{box::set_script_path} should therefore never be necessary.
#' \href{https://github.com/klmr/box/issues/new?assignees=&labels=\%E2\%9A\%A0\%EF\%B8\%8F+bug&title=\%5Bset_script_path\%5D\%20&template=bug-report.yml}{Please
#' file an issue} if you encounter a situation that necessitates using
#' \code{box::set_script_path}!
#'
#' @examples
#' box::set_script_path('scripts/my_script.r')
#' @name script_path
#' @export
set_script_path = function (path = NULL) {
    old_path = script_path()
    script_path_env$script_path = path
    script_path_env$value = if (is.null(path)) NULL else dirname(path)
    invisible(old_path)
}

#' @usage \special{box::script_path()}
#' @rdname script_path
#' @export
script_path = function () {
    script_path_env$script_path
}

#' Get a module’s path
#'
#' The following functions retrieve information about the path of the directory
#' that a module or script is running in.
#' @param mod a module environment or namespace
#' @return \code{path} returns a character string containing the module’s full
#' path.
#' @keywords internal
path = function (mod) {
    UseMethod('path')
}

#' @export
`path.box$mod` = function (mod) {
    attr(mod, 'info')$source_path
}

#' @export
`path.box$ns` = function (mod) {
    namespace_info(mod, 'info')$source_path
}

#' @return \code{base_path} returns a character string containing the module’s
#' base directory, or the current working directory if not invoked on a module.
#' @rdname path
base_path = function (mod) {
    normalizePath(module_path(mod), winslash = '/', mustWork = FALSE)
}

script_path_env = new.env(parent = emptyenv())

#' @return \code{module_path} returns a character string that contains the
#' directory in which the calling R code is run. See \sQuote{Details}.
#' @details
#' \code{module_path} takes a best guess at a script’s path, since R does not
#' provide a sure-fire way for determining the path of the currently executing
#' code. The following calling situations are covered:
#'
#' \enumerate{
#'  \item Path explicitly set via \code{set_script_path}
#'  \item Path of a running document/application (\pkg{knitr}, \pkg{Shiny})
#'  \item Path of unit test cases (\pkg{testthat})
#'  \item Path of the currently opened source code file in RStudio
#'  \item Code invoked as \command{Rscript script.r}
#'  \item Code invoked as \command{R CMD BATCH script.r}
#'  \item Code invoked as \command{R -f script.r}
#'  \item Script run interactively (use \code{getwd()})
#' }
#' @rdname path
module_path = function (mod) {
    for (test in path_tests) {
        path = test(mod)
        if (! is.null(path)) {
            # Don’t cache result, since it might change suddenly, due to knitr
            # or Shiny running in the same process.
            return(path)
        }
    }
    throw('unreachable code')
}

#' @return \code{mod_path} returns the script path associated with a \pkg{box}
#' module
#' @rdname path
mod_path = function (mod) {
    tryCatch(dirname(path(mod)), error = function (e) NULL)
}

#' @return \code{explicit_path} returns the script path explicitly set by the
#' user, if such a path was set.
#' @rdname path
explicit_path = function (...) {
    script_path_env$value
}

#' @param args command line arguments passed to R; by default, the arguments of
#' the current process.
#' @return \code{r_path} returns the directory in which the current script is
#' run via \command{Rscript}, \command{R CMD BATCH} or \command{R -f}.
#' @rdname path
r_path = function (...) {
    args = commandArgs()
    if (length((file_arg = grep('^--file=', args))) != 0L) {
        unescape_path_arg(dirname(sub('--file=', '', args[file_arg])))
    } else if (length((f_arg = grep('^-f$', args))) != 0L) {
        unescape_path_arg(dirname(args[f_arg + 1L]))
    }
}

unescape_path_arg = if (tolower(Sys.info()[['sysname']]) == 'windows') {
    identity
} else {
    function (path) {
        # Translated from src/unix/system.c:unescape_arg
        # But only unescape spaces, not newlines, since the latter are only escaped
        # when passing code via `-e`, never in file paths.
        gsub('~+~', ' ', path, fixed = TRUE)
    }
}

#' @return \code{knitr_path} returns the directory in which the currently knit
#' document is run, or \code{NULL} if not called from within a \pkg{knitr}
#' document.
#' @rdname path
knitr_path = function (...) {
    if (! 'knitr' %in% loadedNamespaces()) return(NULL)

    knitr_input = suppressWarnings(knitr::current_input(dir = TRUE))
    if (! is.null(knitr_input)) dirname(knitr_input)
}

#' @return \code{shiny_path} returns the directory in which a \pkg{Shiny}
#' application is running, or \code{NULL} if not called from within a
#' \pkg{Shiny} application.
#' @rdname path
shiny_path = function (...) {
    if (! 'shiny' %in% loadedNamespaces()) return()
    in_shiny =
        (utils::packageVersion('shiny') < '1.6.0' && shiny::isRunning()) ||
        {
            # `isRunning` no longer works in Shiny 1.6.0:
            # <https://github.com/rstudio/shiny/issues/3499>
            shiny_ns = getNamespace('shiny')
            any(map_lgl(identical, lapply(sys.frames(), topenv), shiny_ns))
        }
    if (in_shiny) getwd()
}

#' @return \code{testthat_path} returns the directory in which \pkg{testthat}
#' code is being executed, or \code{NULL} if not called from within a
#' \pkg{testthat} test case.
#' @rdname path
testthat_path = function (...) {
    if (identical(Sys.getenv('TESTTHAT'), 'true')) getwd()
}

#' @return \code{rstdio_path} returns the directory in which the currently
#' active RStudio script file is saved.
#' @rdname path
rstudio_path = function (...) {
    # .Platform$GUI is not yet set to "RStudio" during startup, so checking for
    # it *might* be insufficient in corner cases.
    # However, we cannot merely check whether the `RSTUDIO` environment
    # variable is set, because it is also set inside the RStudio terminal; and
    # when ‘box’ is invoked from a script that is run in the terminal, we do
    # *not* want to use RStudio’s active document, since that isn’t the script
    # from which we are called.
    # See also comments at <https://stackoverflow.com/a/35849779/1968>.
    if (! identical(.Platform$GUI, 'RStudio')) return(NULL)

    document_path = if (requireNamespace('rstudioapi', quietly = TRUE)) {
        rstudioapi::getActiveDocumentContext()$path
    } else {
        # ‘rstudioapi’ might not be installed. Attempt to use the internal API
        # as a fallback.
        tryCatch(
            as.environment("tools:rstudio")$.rs.api.getActiveDocumentContext()$path,
            error = function (.) {
                warning(fmt(
                    'It looks like the code is run from inside RStudio but ',
                    '{"box";\'} is unable to identify the calling document. This ',
                    'should not happen. Please consider filing a bug report at ',
                    '<https://github.com/klmr/box/issues/new/choose>.'
                ))
                return(NULL)
            }
        )
    }

    if (identical(document_path, '')) {
        # The active document wasn’t saved yet, or the code is invoked from the
        # R REPL/console.
        getwd()
    } else {
        dirname(document_path)
    }
}

#' @return \code{wd_path} returns the current working directory.
#' @rdname path
wd_path = function (...) {
    # Fallback
    getwd()
}

path_test_hooks = c('mod', 'explicit', 'knitr', 'shiny', 'testthat', 'rstudio', 'r', 'wd')
path_tests = mget(paste0(path_test_hooks, '_path'))

#' Path related functions
#'
#' \code{mod_search_path} returns the character vector of paths where module
#' code can be located and will be found by \pkg{box}.
#'
#' @note The search paths are ordered from highest to lowest priority.
#' The current module’s path always has the lowest priority.
#'
#' There are two ways of modifying the module search path: by default,
#' \code{getOption('box.path')} specifies the search path as a character vector.
#' Users can override its value by separately setting the environment variable
#' \env{R_BOX_PATH} to one or more paths, separated by the platform’s path
#' separator (\dQuote{:} on UNIX-like systems, \dQuote{;} on Windows).
#' @keywords internal
#' @name paths
mod_search_path = function (caller) {
    env_value = strsplit(Sys.getenv('R_BOX_PATH'), .Platform$path.sep)[[1L]]
    c(
        env_value %||% getOption('box.path'),
        system_mod_path,
        calling_mod_path(caller)
    )
}

#' \code{calling_mod_path} determines the path of the module code that is
#' currently calling into the \pkg{box} package.
#'
#' @param caller the environment from which \code{box::use} was invoked.
#' @return \code{calling_mod_path} the path of the source module that is calling
#' \code{box::use}, or the script’s path if the calling code is not a module.
#' @rdname paths
calling_mod_path = function (caller) {
    calling_ns = mod_topenv(caller)
    # FIXME: Make work for modules imported inside package, if necessary.
    module_path(calling_ns)
}

#' \code{split_path(path)} is a platform independent and filesystem logic
#' aware alternative to \code{strsplit(path, '/')[[1L]]}.
#' @param path the path to split
#' @return \code{split_path} returns a character vector of path components that
#' logically represent \code{path}.
#' @rdname paths
split_path = function (path) {
    if (identical(path, dirname(path))) {
        path
    } else {
        c(Recall(dirname(path)), basename(path))
    }
}

#' \code{merge_path(split_path(path))} is equivalent to \code{path}.
#' @param components character string vector of path components to merge
#' @return \code{merge_path} returns a single character string that is
#' logically equivalent to the \code{path} passed to \code{split_path}.
#' logically represent \code{path}.
#' @note \code{merge_path} is the inverse function to \code{split_path}.
#' However, this does not mean that its result will be identical to the
#' original path. Instead, it is only guaranteed that it will refer to the same
#' logical path given the same working directory.
#' @rdname paths
merge_path = function (components) {
    do.call('file.path', as.list(components))
}

#' \code{sanitize_path(path)} replaces invalid characters in the given
#' \emph{relative} path, making the result a valid Windows path.
#' @rdname paths
sanitize_path = function (path) {
    win32_reserved_path_chars = '[<>:"/\\|?*]'
    gsub(win32_reserved_path_chars, '_', path)
}

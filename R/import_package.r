#' @param package a character string specifying the package name
#'
#' @rdname import
#' @details
#' \code{pkg = import_package('pkg')} imports a package and treats it much as if
#' it were a module, making package contents available in the \code{pkg}
#' variable.
#' @examples
#' \dontrun{
#' dplyr = import_package('dplyr')
#' # Not attached, so we cannot do:
#' #cars = tbl_df(cars)
#' # Instead, this works:
#' cars = dplyr$tbl_df(cars)
#' # But this invokes the correct `print` method for class `tbl_df`:
#' print(cars)
#' }
#' @export
import_package_ = function (package, attach, attach_operators = TRUE) {
    stopifnot(inherits(package, 'character'))

    if (missing(attach)) {
        attach = if (interactive() && is.null(module_name()))
            getOption('import.attach', FALSE)
        else
            FALSE
    }

    stopifnot(class(attach) == 'logical' && length(attach) == 1)

    module_parent = parent.frame()

    pkg_ns = require_namespace(package)
    if (inherits(pkg_ns, 'error'))
        stop('Unable to load package ', sQuote(package), '\n',
             'Failed with error: ', sQuote(conditionMessage(pkg_ns)))

    # TODO: Use `importIntoEnv`?
    export_list = getNamespaceExports(pkg_ns)
    pkg_env = exhibit_package_namespace(pkg_ns, package, module_parent, export_list)

    attach_module(attach, attach_operators, package, pkg_env, module_parent)

    lockEnvironment(pkg_env, bindings = TRUE)
    invisible(pkg_env)
}

#' @export
#' @rdname import
import_package = function (package, attach, attach_operators = TRUE) {
    # Substitute exactly `import_package` with `import_package_` in call. This
    # ensures that the call works regardless of whether it was bare or
    # qualified (`modules::import_package`).
    call = sys.call()
    call[[1]] = do.call(substitute,
                        list(call[[1]],
                             list(import_package = quote(import_package_))))
    if (! inherits(substitute(package), 'character')) {
        msg = sprintf(paste('Calling %s with a variable will change its',
                            'semantics in version 1.0 of %s. Use %s instead.',
                            'See %s for more information.'),
                      sQuote('import_package'), sQuote('modules'),
                      sQuote(deparse(call)),
                      sQuote('https://github.com/klmr/modules/issues/68'))
        .Deprecated(msg = msg)
    }
    eval.parent(call)
}

# Similar to `base::requireNamespace`, but returns the package namespace,
# doesn’t swallow the error message, and without NSE shenanigans.
require_namespace = function (package) {
    ns = base::.getNamespace(package)
    if (is.null(ns))
        ns = tryCatch(loadNamespace(package), error = identity)

    ns
}

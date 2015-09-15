#' @param package a character string specifying the package name
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
import_package = function (package, attach, attach_operators = TRUE) {
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

    attached_module = if (attach)
        pkg_env
    else if (attach_operators)
        export_operators(pkg_env, module_parent, package)
    else
        NULL

    if (! is.null(attached_module)) {
        # The following distinction is necessary because R segfaults if we try
        # to change `parent.env(.GlobalEnv)`. More info:
        # http://stackoverflow.com/q/22790484/1968
        if (identical(module_parent, .GlobalEnv)) {
            # FIXME: Run .onAttach?
            attach(attached_module, name = environmentName(attached_module))
            attr(pkg_env, 'attached') = environmentName(attached_module)
        }
        else
            parent.env(module_parent) = attached_module
    }

    lockEnvironment(pkg_env, bindings = TRUE)
    invisible(pkg_env)
}

# Similar to `base::requireNamespace`, but returns the package namespace,
# doesn’t swallow the error message, and without NSE shenanigans.
require_namespace = function (package) {
    ns = .Internal(getRegisteredNamespace(package))
    if (is.null(ns))
        ns = tryCatch(loadNamespace(package), error = identity)

    ns
}

exhibit_package_namespace = function (namespace, name, parent, export_list) {
    # See `exhibit_namespace` for an explanation of the structure.
    structure(list2env(sapply(export_list, getExportedValue, ns = namespace,
                              simplify = FALSE),
                       parent = parent.env(parent)),
              name = paste('package', name, sep = ':'),
              path = getNamespaceInfo(namespace, 'path'),
              class = c('package', 'module', 'environment'))
}

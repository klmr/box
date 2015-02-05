import_package = function (package, attach) {
    stopifnot(inherits(package, 'character'))

    if (missing(attach)) {
        attach = if (interactive() && is.null(module_name()))
            getOption('import.attach', FALSE)
        else
            FALSE
    }

    stopifnot(class(attach) == 'logical' && length(attach) == 1 ||
              class(attach) == 'character')

    if (is.character(attach)) {
        export_list = attach
        attach = TRUE
    }
    else
        export_list = NULL

    module_parent = parent.frame()

    # TODO: Do we actually need this? Nothing is attached here, even if loading
    # the package via `library` would attach stuff.
    # Furthermore, S4 functions don’t work, and nor do S3, I’d wager.

    # Package which use `Depends` will pollute the global `search()` path.
    # We save the old `search()` path, and restore it afterwards. Furthermore,
    # We attach the list of attached packages to our local parent environment
    # chain instead.
    old_search = search()
    on.exit({
        if (! identical(module_parent, .GlobalEnv)) {
            newly_attached = setdiff(search(), old_search)
            for (pkg in newly_attached)
                detach(pkg)

            # Insert them into the current package’s parent chain.
            # We only need to insert the first one, since it already has the
            # others as its parents.
            # NOTE: This relies on the fact that `setdiff` doesn’t change the
            # order of the elements.

            parent.env(tail(newly_attached, 1)) = parent.env(module_parent)
            parent.env(module_parent) = newly_attached[1]
        }
    })

    pkg_ns = require_namespace(package)
    if (inherits(pkg_ns, 'error'))
        stop('Unable to load packge ', sQuote(package), '\n',
             'Failed with error: ', sQuote(conditionMessage(pkg_ns)))

    # TODO: Handle attaching

    pkg_ns
}

# Similar to `base::requireNamespace`, but returns the package namespace,
# doesn’t swallow the error message, and without NSE shenanigans.
require_namespace = function(package) {
    ns = .Internal(getRegisteredNamespace(package))
    if (is.null(ns))
        ns = tryCatch(loadNamespace(package), error = identity)

    ns
}

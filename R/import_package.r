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

    # TODO: Do we actually need this? Nothing is attached here, even if loading
    # the package via `library` would attach stuff.
    # We can also just opt to blatantly ignore `Depends` packages.
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
        stop('Unable to load package ', sQuote(package), '\n',
             'Failed with error: ', sQuote(conditionMessage(pkg_ns)))

    # TODO: Handle attaching

    # TODO: Return entries from  `.__NAMESPACE__.$exports`
    # FIXME: Wrong environment name set (is: 'module:packagename')
    # FIXME: Can the following ever differ from its contents, i.e. is
    #   all.equal(ls(…$exports), sapply(ls(…$exports), get, envir = …$exports))?
    export_list = getNamespaceExports(pkg_ns)
    # TODO: Use `importIntoEnv`
    pkg_env = exhibit_namespace(pkg_ns, package, module_parent, export_list)

    # FIXME Is this needed?
    pkg_env$.__S3MethodsTable__. = pkg_ns$.__S3MethodsTable__.

    attached_module = if (attach)
        pkg_env
    else if (attach_operators)
        export_operators(pkg_ns, module_parent)
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
require_namespace = function(package) {
    ns = .Internal(getRegisteredNamespace(package))
    if (is.null(ns))
        ns = tryCatch(loadNamespace(package), error = identity)

    ns
}

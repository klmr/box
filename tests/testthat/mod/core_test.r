box::use(testthat[...])

.on_load = function (ns) {
    run = 0L
    core_pkgs = c('methods', 'stats', 'graphics', 'grDevices', 'utils')

    # Find an exported name from each of these core packages to use for testing.
    names = vapply(core_pkgs, function (p) getNamespaceExports(p)[1L], character(1L))

    find_in_parents = function (name) {
        found = c()
        env = parent.env(parent.frame())
        while (! identical(env, emptyenv())) {
            if (name %in% names(env)) found = c(found, environmentName(env))
            env = parent.env(env)
        }
        found
    }

    name_found = function (name, pkg) {
        where = paste0('package:', pkg)
        where %in% eval.parent(bquote(find_in_parents(.(name))))
    }

    # Ensure that names from default packages are not found prior to import.

    for (i in seq_along(core_pkgs)) {
        info = sprintf('%s::%s is attached', core_pkgs[i], names[i])
        expect_false(name_found(names[i], core_pkgs[i]), info = info)
        run = run + 1L
    }

    # Now attach R default packages and ensure their names can be found.

    box::use(r/core[...])

    imports = ls(parent.env(environment()), all.names = TRUE)

    for (name in names) {
        label = sprintf("'%s' %%in%% imports", name)
        expect_true(name %in% imports, label = label)
        run = run + 1L
    }

    ns$tests_run = run
}

#' @export
tests_run = 0L

if (getRversion() < '4.0.0') {
    deparse1 = function (expr, collapse = ' ', width.cutoff = 500L, ...) {
        paste(deparse(expr, width.cutoff, ...), collapse = collapse)
    }

    activeBindingFunction = function (sym, env) {
        as.list(`class<-`(env, NULL), all.names = TRUE)[[sym]]
    }

    R_user_dir = function (package, which) {
        types = c('DATA', 'CONFIG', 'CACHE')
        r = paste0('R_USER_', types, '_DIR')
        xdg = paste0('XDG_', types, '_HOME')

        which = match(toupper(which), types)
        path = (
            if (nzchar({p = Sys.getenv(r[which])})) p
            else if (nzchar({p = Sys.getenv(xdg[which])})) p
            else if (.Platform$OS.type == 'windows') {
                base = Sys.getenv(c('APPDATA', 'APPDATA', 'LOCALAPPDATA')[which])
                file.path(base, 'R', tolower(types)[which])
            } else if (Sys.info()['sysname'] == 'Darwin') {
                base = cbind(
                    '~', 'Library',
                    c('Application Support', 'Preferences', 'Caches')
                )
                do.call('file.path', as.list(c(base[which, ], 'org.R-project.R')))
            } else {
                root = list(c('.local', 'share'), '.config', '.cache')[[which]]
                do.call('file.path', as.list(c('~', root)))
            }
        )

        normalizePath(file.path(path, 'R', package))
    }
} else {
    R_user_dir = tools::R_user_dir
}

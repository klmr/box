# Displaying HTML help for modules was always tricky, since R’s mechanism of serving HTML help via
# a web server is fundamentally tied to packages. The previous implementation was therefore always
# a hack, which started breaking due to changes in R 4.1.0 (see https://github.com/klmr/box/issues/255).
#
# Rather than hack around the new limitations, the following implements HTML documentation for
# modules by installing empty dummy packages with compiled documentation into a cache location. The
# cached packages get replaced whenever the module code changes (based on file timestamps).
# The temporary location gets added to the library search path when the documentation is invoked,
# and gets removed immediately afterwards, to avoid causing user-visible changes.

create_doc_pkg = function (mod, spec, doc_pkg_dir) {
    unlink(doc_pkg_dir, recursive = TRUE)
    map(dir.create, file.path(doc_pkg_dir, c('Meta', 'R', 'help', 'html')), recursive = TRUE)
    description = data.frame(
        Package = spec_name(spec),
        Title = '', Descrption = '', Version = '1.0.0',
        Authors = '', Depends = '', Imports = '', License = '',
        `box/doc/ctime` = unclass(Sys.time()),
        check.names = FALSE
    )
    write.dcf(description, file.path(doc_pkg_dir, 'DESCRIPTION'))

    write_pkg_documentation(mod, mod_ns, doc_pkg_dir)
}

write_pkg_documentation = function (mod, mod_ns, doc_pkg_dir) {
    # FIXME: Requires changing documentation structure. See `test.r`.
    docs = namespace_info(mod_ns, 'doc')
    saveRDS(namespace_info(mod_ns, 'aliases'), file.path(doc_pkg_dir, 'help/aliases.rds'))
}

is_doc_package_up_to_date = function (mod, doc_pkg_dir) {
    desc = file.path(doc_pkg_dir, 'DESCRIPTION')
    if (! file.exists(desc)) return(FALSE)
    doc_pkg_age = structure(read.dcf(desc)[, 'box/doc/ctime'], class = c('POSIXct', 'POSIXt'))
    mod_age = max(file.mtime(dir(mod_path(mod), pattern = '\\.[rR]$', recursive = TRUE, full.names = TRUE)))
    doc_pkg_age >= mod_age
}

# TODO: Probably not good to implement as `print` method here.
print.box_help_files_with_topic = function (x, ...) {
    lib_loc = .libPaths()
    doc_lib = mod_doc_pkg_library

    mod = ..1
    spec = ..2
    #mod_ns = attr(mod, 'namespace')
    mod_ns = ..3

    # Set directly to avoid interference from normalization inside `.libPaths()`.
    environment(.libPaths)$.lib.loc = c(doc_lib, .libPaths())
    on.exit({environment(.libPaths)$.lib.loc = lib_loc})

    pkg_dir_slug = paste0(sanitize_path_fragment(spec_name(spec)), '-', hash_path(mod_path(mod)))
    doc_pkg_dir = file.path(doc_lib, pkg_dir_slug)

    if (! is_doc_package_up_to_date(mod, doc_pkg_dir)) create_doc_pkg(mod, spec, dock_pkg_dir)
}

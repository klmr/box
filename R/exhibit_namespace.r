#' Exhibit objects from an internal module namespace as an environment
#'
#' @param namespace the namespace to export object from
#' @param name the name of the resulting environment
#' @param parent the parent environment of the resulting environment
#' @param export_list the list of objects to export; if \code{NULL}, export
#' everything
#' @param objects named list of objects
#' @param path the fully resolved path to the corresponding module or package
#' @param doc the module documentation
#' @return Returns the resulting environment.
exhibit_namespace = function (objects, name, path, doc, parent) {
    # Skip one parent environment because this module is hooked into the chain
    # between the calling environment and its ancestor, thus sitting in its
    # local object search path.

    env = list2env(objects, parent = parent.env(parent))
    module_attr(env, 'path') = path
    module_attr(env, 'name') = name
    class = c(if (grepl('^package:', name)) 'package', 'module', 'environment')
    structure(env, name = name, doc = doc, class = class)
}

#' 
#' \code{exhibit_module_namespace} exports a namespace for a module.
#' @rdname exhibit_namespace
exhibit_module_namespace = function (namespace, name, parent, export_list) {
    if (is.null(export_list))
        export_list = ls(namespace)
    else {
        # Verify correctness.
        exist = vapply(export_list, exists, logical(1), envir = namespace)
        if (! all(exist))
            stop(sprintf('Non-existent function(s) (%s) specified for import',
                         paste(export_list[! exist], collapse = ', ')))
    }

    exhibit_namespace(mget(export_list, envir = namespace),
                      paste('module', name, sep = ':'),
                      module_path(namespace),
                      attr(namespace, 'doc'),
                      parent)
}

#' 
#' \code{exhibit_package_namespace} exports a namespace for a package.
#' @rdname exhibit_namespace
exhibit_package_namespace = function (namespace, name, parent, export_list) {
    objects = sapply(export_list, getExportedValue, ns = namespace, simplify = FALSE)
    exhibit_namespace(objects,
                      paste('package', name, sep = ':'),
                      getNamespaceInfo(namespace, 'path'),
                      NULL,
                      parent)
}

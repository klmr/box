exhibit_namespace = function (objects, name, path, doc, parent) {
    # Skip one parent environment because this module is hooked into the chain
    # between the calling environment and its ancestor, thus sitting in its
    # local object search path.

    # FIXME: Store original environment info for all functions, as described in #66.
    structure(list2env(objects, parent = parent.env(parent)),
              name = name,
              path = path,
              doc = doc,
              class = c(if (grepl('^package:', name)) 'package', 'module', 'environment'))
}

#' Import a module or package
#'
#' \code{box::use} imports one or more modules and/or packages, and makes them
#' available in the calling environment.
#'
#' @usage \special{box::use(prefix/mod, \dots)}
#' @usage \special{box::use(pkg, \dots)}
#' @usage \special{box::use(alias = prefix/mod, \dots)}
#' @usage \special{box::use(alias = pkg, \dots)}
#' @usage \special{box::use(prefix/mod[attach_list], \dots)}
#' @usage \special{box::use(pkg[attach_list], \dots)}
#'
#' @param prefix/mod a qualified module name
#' @param pkg a package name
#' @param alias an alias name
#' @param attach_list a list of names to attached, optionally witha aliases of
#' the form \code{alias = name}; or the special placeholder name \code{\dots}
#' @param \dots further import declarations
#' @return \code{box::use} has no return value. It is called for its
#' side effect.
#'
#' @details
#' \code{box::use(\dots)} specifies a list of one or more import declarations,
#' given as individual arguments to \code{box::use}, separated by comma.
#' \code{box::use} permits using a trailing comma after the last import
#' declaration. Each import declaration takes one of the following forms:
#'
#' \describe{
#' \item{\code{\var{prefix}/\var{mod}}:}{
#'      Import a module given the qualified module name
#'      \code{\var{prefix}/\var{mod}} and make it available locally using the
#'      name \code{\var{mod}}. The \code{\var{prefix}} itself can be a nested
#'      name to allow importing specific submodules. \emph{Local imports} can be
#'      specified via the prefixes starting with \code{.} and \code{..}, to
#'      override the search path and use the local path instead. See the
#'      \sQuote{Search path} below for details.
#' }
#' \item{\code{\var{pkg}}:}{
#'      Import a package \code{\var{pkg}} and make it available locally using its own
#'      package name.
#' }
#' \item{\code{\var{alias} = \var{prefix}/\var{mod}} or \code{\var{alias} = \var{pkg}}:}{
#'      Import a module or package, and make it available locally using the name
#'      \code{\var{alias}} instead of its regular module or package name.
#' }
#' \item{\code{\var{prefix}/\var{mod}[\var{attach_list}]} or \code{\var{pkg}[\var{attach_list}]}:}{
#'      Import a module or package and attach the exported symbols listed in
#'      \code{\var{attach_list}} locally. This declaration does \emph{not} make
#'      the module/package itself available locally. To override this, provide
#'      an alias, that is, use \code{\var{alias} =
#'      \var{prefix}/\var{mod}[\var{attach_list}]} or \code{\var{alias} =
#'      \var{pkg}[\var{attach_list}]}.
#'
#'      The \code{\var{attach_list}} is a comma-separated list of names,
#'      optionally with aliases assigned via \code{alias = name}. The list can
#'      also contain the special symbol \code{\dots}, which causes \emph{all}
#'      exported names of the module/package to be imported.
#' }
#' }
#'
#' See the vignette at \code{vignette('box', 'box')} for detailed examples of
#' the different types of use declarations listed above.
#'
#' @section Import semantics:
#' Modules and packages are loaded into dedicated namespace environments. Names
#' from a module or package can be selectively attached to the current scope as
#' shown above.
#'
#' Unlike with \code{\link[base]{library}}, attaching happens \emph{locally},
#' i.e. in the caller’s environment: if \code{box::use} is executed in the
#' global environment, the effect is the same. Otherwise, the effect of
#' importing and attaching a module or package is limited to the caller’s local
#' scope (its \code{environment()}). When used \emph{inside a module} at module
#' scope, the newly imported module is only available inside the module’s scope,
#' not outside it (nor in other modules which might be loaded).
#'
#' Member access of (non-attached) exported names of modules and packages
#' happens via the \code{$} operator. This operator does not perform partial
#' argument matching, in contrast with the behavior of the \code{$} operator in
#' base \R, which matches partial names.
#'
#' @section Export specification:
#'
#' Names defined in modules can be marked as \emph{exported} by prefixing them
#' with an \code{@export} tag comment; that is, the name needs to be immediately
#' prefixed by a comment that reads, verbatim, \code{#' @export}. That line may
#' optionally be part of a \pkg{roxygen2} documentation for that name.
#'
#' Alternatively, exports may be specified via the
#' \code{\link[=export]{box::export}} function, but using declarative
#' \code{@export} tags is generally preferred.
#'
#' A module which has not declared any exports is treated as a \emph{legacy
#' module} and exports \emph{all} default-visible names (that is, all names that
#' do not start with a dot (\code{.}). This usage is present only for backwards
#' compatibility with plain \R scripts, and its usage is \emph{not recommended}
#' when writing new modules.
#'
#' To define a module that exports no names, call \code{box::export()} without
#' arguments. This prevents the module from being treated as a legacy module.
#'
#' @section Search path:
#' Modules are searched in the module search path, given by
#' \code{getOption('box.path')}. This is a character vector of paths to search,
#' from the highest to the lowest priority. The current directory is always
#' considered last. That is, if a file \file{a/b.r} exists both locally in the
#' current directory and in a module search path, the local file \file{./a/b.r}
#' will \emph{not} be loaded, unless the import is explicitly declared as
#' \code{box::use(./a/b)}.
#'
#' Modules in the module search path \emph{must be organised in subfolders}, and
#' must be imported fully qualified. Keep in mind that \code{box::use(name)}
#' will \emph{never} attempt to load a module; it always attempts to load a
#' package. A common module organisation is by project, company or user name;
#' for instance, fully qualified module names could mirror repository names on
#' source code sharing websites (such as GitHub).
#'
#' Given a declaration \code{box::use(a/b)} and a search path \file{\var{p}}, if
#' the file \file{\var{p}/a/b.r} does not exist, \pkg{box} alternatively looks
#' for a nested file \file{\var{p}/a/b/__init__r} to load. Module path names are
#' \emph{case sensitive} (even on case insensitive file systems), but the file
#' extension can be spelled as either \file{.r} or \file{.R} (if both exist,
#' \code{.r} is given preference).
#'
#' The module search path can be overridden by the environment variable
#' \env{R_BOX_PATH}. If set, it may consist of one or more search paths,
#' separated by the platform’s path separator (i.e. \code{;} on Windows, and
#' \code{:} on most other platforms).
#'
#' The \emph{current directory} is context-dependent: inside a module, the
#' directory corresponds to the module’s directory. Inside an \R code file
#' invoked from the command line, it corresponds to the directory containing
#' that file. If the code is running inside a \pkg{Shiny} application or a
#' \pkg{knitr} document, the directory of the execution is used. Otherwise (e.g.
#' in an interactive \R session), the current working directory as given by
#' \code{getwd()} is used.
#'
#' Local import declarations (that is, module prefixes that start with \code{./}
#' or \code{../}) never use the search path to find the module. Instead,
#' only the current module’s directory (for \code{./}) or the parent module’s
#' directory (for \code{../}) is looked at. \code{../} can be nested:
#' \code{../../} denotes the grandparent module, etc.
#'
#' @section S3 support:
#' Modules can contain S3 generics and methods. To override known generics
#' (= those defined outside the module), methods inside a module need to be
#' registered using \code{\link[=register_S3_method]{box::register_S3_method}}.
#' See the documentation there for details.
#'
#' @section Module names:
#' A module’s full name consists of one or more \R names separated by \code{/}.
#' Since \code{box::use} declarations contain \R expressions, the names need to
#' be valid \R names. Non-syntactic names need to be wrapped in backticks; see
#' \link[base]{Quotes}.
#'
#' Furthermore, since module names usually correspond to file or folder names,
#' they should consist only of valid path name characters to ensure portability.
#'
#' @section Encoding:
#' All module source code files are assumed to be UTF-8 encoded.
#'
#' @examples
#' # Set the module search path for the example module.
#' old_opts = options(box.path = system.file(package = 'box'))
#'
#' # Basic usage
#' # The file `mod/hello_world.r` exports the functions `hello` and `bye`.
#' box::use(mod/hello_world)
#' hello_world$hello('Robert')
#' hello_world$bye('Robert')
#'
#' # Using an alias
#' box::use(world = mod/hello_world)
#' world$hello('John')
#'
#' # Attaching exported names
#' box::use(mod/hello_world[hello])
#' hello('Jenny')
#' # Exported but not attached, thus access fails:
#' try(bye('Jenny'))
#'
#' # Attach everything, give `hello` an alias:
#' box::use(mod/hello_world[hi = hello, ...])
#' hi('Eve')
#' bye('Eve')
#'
#' # Reset the module search path
#' on.exit(options(old_opts))
#'
#' \dontrun{
#' # The following code illustrates different import declaration syntaxes
#' # inside a single `box::use` declaration:
#'
#' box::use(
#'     global/mod,
#'     mod2 = ./local/mod,
#'     purrr,
#'     tbl = tibble,
#'     dplyr = dplyr[filter, select],
#'     stats[st_filter = filter, ...],
#' )
#'
#' # This declaration makes the following names available in the caller’s scope:
#' #
#' # 1. `mod`, which refers to the module environment for  `global/mod`
#' # 2. `mod2`, which refers to the module environment for `./local/mod`
#' # 3. `purrr`, which refers to the package environment for ‘purrr’
#' # 4. `tbl`, which refers to the package environment for ‘tibble’
#' # 5. `dplyr`, which refers to the package environment for ‘dplyr’
#' # 6. `filter` and `select`, which refer to the names exported by ‘dplyr’
#' # 7. `st_filter`, which refers to `stats::filter`
#' # 8. all other exported names from the ‘stats’ package
#' }
#' @seealso
#' \code{\link[=name]{box::name}} and \code{\link[=file]{box::file}} give
#' information about loaded modules.
#' \code{\link[=help]{box::help}} displays help for a module’s exported names.
#' \code{\link[=unload]{box::unload}} and \code{\link[=reload]{box::reload}} aid
#' during module development by performing dynamic unloading and reloading of
#' modules in a running \R session.
#' \code{\link[=export]{box::export}} can be used as an alternative to
#' \code{@export} comments inside a module to declare module exports.
#' @export
use = function (...) {
    caller = parent.frame()
    call = match.call()
    imports = call[-1L]
    aliases = names(imports) %||% character(length(imports))
    map(use_one, imports, aliases, list(caller), use_call = list(sys.call()))
    invisible()
}

#' Import a module or package
#'
#' Actual implementation of the import process
#'
#' @details
#' \code{use_one} performs the actual import. It is invoked by \code{use} given
#' the calling context and unevaluated expressions as arguments, and only uses
#' standard evaluation.
#'
#' \code{load_and_register} performs the loading, attaching and exporting of a
#' module identified by its spec and info.
#'
#' \code{register_as_import} registers a \code{use} declaration in the calling
#' module so that it can be found later on, if the declaration is reexported by
#' the calling module.
#'
#' \code{defer_import_finalization} is called by \code{load_and_register} to
#' earmark a module for deferred initialization if it hasn’t been fully loaded
#' yet.
#'
#' \code{finalize_deferred} exports and attaches names from a module use
#' declaration which has been deferred due to being part of a cyclic loading
#' chain.
#'
#' \code{export_and_attach} exports and attaches names from a given module use
#' declaration.
#'
#' \code{load_from_source} loads a module source file into its newly created,
#' empty module namespace.
#'
#' \code{load_mod} tests whether a module or package was already loaded and, if
#' not, loads it.
#'
#' \code{mod_exports} returns an export environment containing a copy of the
#' module’s exported objects.
#'
#' \code{attach_to_caller} attaches the listed names of an attach specification
#' for a given use declaration to the calling environment.
#'
#' \code{assign_alias} creates a module/package object in calling environment,
#' unless it contains an attach declaration, and no explicit alias is given.
#'
#' \code{assign_temp_alias} creates a placeholder object for the module in the
#' calling environment, to be replaced by the actual module export environment
#' once the module is completely loaded (which happens in the case of cyclic
#' imports).
#' @param declaration an unevaluated use declaration expression without the
#' surrounding \code{use} call
#' @param alias the use alias, if given, otherwise \code{NULL}
#' @param caller the client’s calling environment (parent frame)
#' @param use_call the \code{use} call which is invoking this code
#' @return \code{use_one} does not currently return a value. — This might change
#' in the future.
#' @note If a module is still being loaded (because it is part of a cyclic
#' import chain), \code{load_and_register} earmarks the module for deferred
#' registration and holds off on attaching and exporting for now, since not all
#' its names are available yet.
#' @keywords internal
#' @name importing
use_one = function (declaration, alias, caller, use_call) {
    # Permit empty expression resulting from trailing comma.
    if (identical(declaration, quote(expr =)) && identical(alias, '')) return()

    rethrow_on_error({
        spec = parse_spec(declaration, alias)
        info = find_mod(spec, caller)
        load_and_register(spec, info, caller)
    }, call = use_call)
}

#' @param spec a module use declaration specification
#' @param info the physical module information
#' @rdname importing
load_and_register = function (spec, info, caller) {
    mod_ns = load_mod(info)
    register_as_import(spec, info, mod_ns, caller)

    if (is_mod_still_loading(info)) {
        # Module was cached but hasn’t fully loaded yet. This happens for
        # cyclic imports (1. A -> 2. B -> 3. A)) in step (3). To proceed, we
        # take note of the issue and wait until we bounce back to step (1) to
        # perform deferred finalization.

        assign_temp_alias(spec, caller)
        defer_import_finalization(spec, info, mod_ns, caller)
        return()
    }

    export_and_attach(spec, info, mod_ns, caller)
}

#' @param mod_ns the module namespace environment of the newly loaded module
#' @rdname importing
register_as_import = function (spec, info, mod_ns, caller) {
    if (is_namespace(caller)) {
        # Import declarations are stored in a list in the module metadata
        # dictionary. They are looked up by their spec.
        import = import_decl(ns = mod_ns, spec = spec, info = info)
        existing_imports = namespace_info(caller, 'imports', list())
        namespace_info(caller, 'imports') = c(existing_imports, list(import))
    }
}

#' @rdname importing
defer_import_finalization = function (spec, info, mod_ns, caller) {
    defer_args = as.list(environment())
    existing_deferred = attr(loaded_mods[[info$source_path]], 'deferred')
    attr(loaded_mods[[info$source_path]], 'deferred') =
        c(existing_deferred, list(defer_args))
}

#' @rdname importing
finalize_deferred = function (info) {
    UseMethod('finalize_deferred')
}

`finalize_deferred.box$mod_info` = function (info) {
    deferred = attr(loaded_mods[[info$source_path]], 'deferred')
    if (is.null(deferred)) return()

    attr(loaded_mods[[info$source_path]], 'deferred') = NULL

    for (defer_args in deferred) {
        do.call(export_and_attach, defer_args)
    }
}

`finalize_deferred.box$pkg_info` = function (info) {}

#' @rdname importing
export_and_attach = function (spec, info, mod_ns, caller) {
    finalize_deferred(info)

    mod_exports = mod_exports(info, spec, mod_ns)
    lockEnvironment(mod_exports, bindings = TRUE)

    assign_alias(spec, mod_exports, caller)
    attach_to_caller(spec, info, mod_exports, mod_ns, caller)
}

#' @rdname importing
load_from_source = function (info, mod_ns) {
    # R, Windows and Unicode don’t play together. `source` does not work here.
    # See http://developer.r-project.org/Encodings_and_R.html and
    # http://stackoverflow.com/q/5031630/1968 for a discussion of this.
    exprs = parse(info$source_path, keep.source = TRUE, encoding = 'UTF-8')
    eval(exprs, mod_ns)

    if (is.null(namespace_info(mod_ns, 'exports'))) {
        exports = parse_export_specs(info, exprs, mod_ns)
        is_legacy = length(exports) == 0L
        namespace_info(mod_ns, 'legacy') = is_legacy
        namespace_info(mod_ns, 'exports') = if (is_legacy) ls(mod_ns) else exports
    }

    make_S3_methods_known(mod_ns)
}

#' @return \code{load_mod} returns the module or package namespace environment
#' of the specified module or package info.
#' @rdname importing
load_mod = function (info) {
    UseMethod('load_mod')
}

`load_mod.box$mod_info` = function (info) {
    if (is_mod_loaded(info)) return(loaded_mod(info))

    # Load module/package and dependencies; register the module now, to allow
    # cyclic imports without recursing indefinitely — but deregister upon
    # failure to load.
    on.exit(deregister_mod(info))

    mod_ns = make_namespace(info)
    register_mod(info, mod_ns)
    load_from_source(info, mod_ns)
    mod_loading_finished(info, mod_ns)

    # Call `.on_load` hook just after loading is finished but before exporting
    # symbols, so that `.on_load` can modify these symbols.
    call_hook(mod_ns, '.on_load', mod_ns)
    lockEnvironment(mod_ns, bindings = TRUE)

    on.exit()
    mod_ns
}

`load_mod.box$pkg_info` = function (info) {
    pkg = info$name
    base::.getNamespace(pkg) %||% loadNamespace(pkg)
}

#' @return \code{mod_exports} returns an export environment containing the
#' exported names of a given module.
#' @rdname importing
mod_exports = function (info, spec, mod_ns) {
    exports = mod_export_names(info, mod_ns)
    env = make_export_env(info, spec, mod_ns)
    import_into_env(env, exports, mod_ns, exports)
    env
}

#' @return \code{mode_export_names} returns a vector containing the same names as
#' \code{names(mod_exports(info, spec, mod_ns))} but does not create an export
#' environment.
#' @rdname importing
mod_export_names = function (info, mod_ns) {
    UseMethod('mod_export_names')
}

`mod_export_names.box$mod_info` = function (info, mod_ns) {
    namespace_info(mod_ns, 'exports')
}

`mod_export_names.box$pkg_info` = function (info, mod_ns) {
    c(getNamespaceExports(mod_ns), ls(getNamespaceInfo(mod_ns, 'lazydata')))
}

#' @rdname importing
attach_to_caller = function (spec, info, mod_exports, mod_ns, caller) {
    attach_list = attach_list(spec, names(mod_exports))
    if (is.null(attach_list)) return()

    import_env = find_import_env(caller, spec, info, mod_ns)
    attr(mod_exports, 'attached') = environmentName(import_env)
    import_into_env(import_env, names(attach_list), mod_exports, attach_list)
}

#' @return \code{attach_list} returns a named character vector of the names in
#' an attach specification. The vector’s names are the aliases, if provided, or
#' the attach specification names themselves otherwise.
#' @rdname importing
attach_list = function (spec, exports) {
    if (is.null(spec$attach)) return()
    is_wildcard = is.na(spec$attach)
    name_spec = spec$attach[! is_wildcard]

    if (! all(is_wildcard) && any((what = ! name_spec %in% exports))) {
        missing = name_spec[what]
        throw(
            'name{s} {missing;"} not exported by {spec_name(spec);"}',
            s = if (length(missing) > 1L) 's' else ''
        )
    }

    if (any(is_wildcard)) {
        if (length(exports) == 0L) return()

        aliases = exports
        if (length(spec$attach) > 1L) {
            # Substitute aliased names in export list
            to_replace = match(name_spec, exports)
            aliases[to_replace] = names(name_spec)
        }

        stats::setNames(exports, aliases)
    } else {
        name_spec
    }
}

#' @rdname importing
assign_alias = function (spec, mod_exports, caller) {
    create_mod_alias = is.null(spec$attach) || spec$explicit
    if (! create_mod_alias) return()

    if (exists(spec$alias, caller, inherits = FALSE) && bindingIsLocked(spec$alias, caller)) {
        box_unlock_binding(spec$alias, caller)
    }
    assign(spec$alias, mod_exports, envir = caller)
}

#' @rdname importing
assign_temp_alias = function (spec, caller) {
    create_mod_alias = is.null(spec$attach) || spec$explicit
    if (! create_mod_alias) return()

    callers = list()

    binding = function (mod_exports) {
        if (missing(mod_exports)) {
            # Find from where I’m called, and infer the target of the export.
            mod_exports_frame_index = utils::tail(which(map_lgl(
                function (call) identical(call[[1L]], quote(mod_exports)),
                sys.calls()
            )), 1L)
            frame = sys.frame(mod_exports_frame_index)
            env = frame$env
            assign('callers', append(callers, env), envir = parent.env(environment()))

            # FIXME: Do we need to create transitive placeholder active bindings?
            structure(list(), class = 'placeholder')
        } else {
            # Resolve assignments
            for (env in callers) {
                box_unlock_binding(spec$alias, env)
                assign(spec$alias, mod_exports, envir = env)
                lockBinding(spec$alias, env)
            }
            # Replace myself
            unlock_environment(caller)
            rm(list = spec$alias, envir = caller)
            assign(spec$alias, mod_exports, envir = caller)
            lockEnvironment(caller)
        }
    }

    makeActiveBinding(spec$alias, structure(binding, class = 'box$placeholder'), caller)
}

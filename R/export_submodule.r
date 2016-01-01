#' Export a given submodule from the current module
#'
#' @param submodule character string of length 1 with the name of the submodule
#' @note Sometimes, a module may want to export all or some of its submodules in
#' bulk. Simply doing \code{import('submodule', attach = TRUE)} won’t work,
#' however, since \code{attach} only has a local effect. \code{export_submodule},
#' by contrast, exports a submodule’s contents as if they were defined directly
#' inside the current module.
#' @examples
#' \dontrun{
#' # x/__init__.r:
#' export_submodule('./foo')
#'
#' # x/foo.r:
#' answer_to_life = function () 42
#'
#' # Calling code can now use the above modules:
#' x = import('x')
#' x$answer_to_life() # returns 42
#' }
#' @rdname export_submodule
export_submodule_ = function (submodule) {
    parent = parent.frame()
    call = bquote(import_(.(submodule), attach_operators = FALSE))
    module = eval.parent(call)
    expose_single = function (symbol)
        assign(symbol, get(symbol, envir = module), envir = parent)
    invisible(lapply(ls(module), expose_single))
}

export_submodule = function (submodule) {
    call = `[[<-`(sys.call(), 1, quote(export_submodule_))
    if (! inherits(substitute(submodule), 'character')) {
        msg = sprintf(paste('Calling %s with a variable will change its',
                            'semantics in version 1.0 of %s. Use %s instead.',
                            'See %s for more information.'),
                      sQuote('export_submodule'), sQuote('modules'),
                      sQuote(deparse(call)),
                      sQuote('https://github.com/klmr/modules/issues/68'))
        .Deprecated(msg = msg)
    }
    eval.parent(call)
}

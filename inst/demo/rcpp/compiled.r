# Load compiled module meta information, and load R wrapper code, which, in
# turn, loads the compiled module via `dyn.load`.
load_dynamic = function (prefix) {
    load(module_file(sprintf('%s.rdata', prefix)))
    source(context$rSourceFile, local = parent.frame())
}

load_dynamic('convolve')

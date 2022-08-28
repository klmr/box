context('vignettes')

expect_snapshot_vignette = function (out_dir, vignette) {
    name = paste0(tools::file_path_sans_ext(vignette), '.md')
    output_path = file.path(out_dir, name)

    announce_snapshot_file(name = name)
    expect_snapshot_file(output_path, name, compare = compare_file_vignette)
}

compare_file_vignette = function (old, new) {
    old = readLines(old)
    new = readLines(new)

    mask_env_ptrs = function (x) {
        gsub('## <environment: 0x[0-9a-f]+>', '## <environment: X>', x)
    }

    # Mask out non-deterministic values in code output, in particular pointer
    # values in the output of R environments.
    identical(mask_env_ptrs(old), mask_env_ptrs(new))
}

test_that('vignettes don’t change', {
    local_edition(3L)
    pkgdir = '../..'
    out_dir = file.path(pkgdir, 'doc')
    vignettes = dir(file.path(pkgdir, 'vignettes'), pattern = '\\.rmd$')

    skip_on_cran()
    skip_on_ci()
    skip_if(! dir.exists(out_dir))

    if (! setequal(vignettes, sub('\\.md$', '.rmd', dir(out_dir, pattern = '\\.md$')))) {
        fail('One or more rendered vignettes were missing. Run `make knit-all`!')
        skip('Skipping vignette snapshot tests')
    }

    for (vignette in vignettes) {
        expect_snapshot_vignette(out_dir, vignette)
    }
})

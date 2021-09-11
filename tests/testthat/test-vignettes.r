context('vignettes')

expect_snapshot_vignette = function (out_dir, vignette) {
    name = paste0(tools::file_path_sans_ext(vignette), '.md')
    output_path = file.path(out_dir, name)

    announce_snapshot_file(name = name)
    expect_snapshot_file(output_path, name, compare = compare_file_text)
}

test_that('vignettes don’t change', {
    local_edition(3L)
    pkgdir = '../..'
    out_dir = file.path(pkgdir, 'doc')
    vignettes = dir(file.path(pkgdir, 'vignettes'), pattern = '*.rmd')

    skip_on_cran()
    skip_on_ci()
    skip_if(! dir.exists(out_dir))

    for (vignette in vignettes) {
        expect_snapshot_vignette(out_dir, vignette)
    }
})

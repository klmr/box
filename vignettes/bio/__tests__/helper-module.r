# Necessary (for now) since testthat manually sets the working dir.
box::set_script_path('../seq.r')

# Load the module to be tested
box::use(./seq[...])

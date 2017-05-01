devtools::load_all(quiet = TRUE)
options(import.path = 'inst/tests/modules')

before = module_name()
a = import('a')
after = module_name()

before; after

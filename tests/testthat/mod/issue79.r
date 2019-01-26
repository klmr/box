devtools::load_all(quiet = TRUE)

before = module_name()
a = import('a')
after = module_name()

before; after

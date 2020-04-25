devtools::load_all(quiet = TRUE)

before = xyz::name()
xyz::use(./a)
after = xyz::name()

before; after

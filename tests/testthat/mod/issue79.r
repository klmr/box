devtools::load_all(quiet = TRUE)

before = mod::name()
mod::use(./a)
after = mod::name()

before; after

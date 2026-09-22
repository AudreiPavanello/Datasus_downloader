library(testthat)

# Os testes cobrem apenas as funções puras de R/constants.R, R/dictionaries.R e
# R/helpers.R. Nada aqui toca a rede: o FTP do DATASUS não é testável de forma
# determinística e já é responsabilidade do microdatasus.
source("../R/constants.R")
source("../R/dictionaries.R")
source("../R/helpers.R")

test_dir("testthat")

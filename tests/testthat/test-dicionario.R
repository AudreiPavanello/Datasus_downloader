amostra_fixture <- function() {
  data.frame(
    DTOBITO = c("01012023", "02012023", NA),
    SEXO = c("1", "2", "1"),
    VAZIA = c(NA_character_, NA_character_, NA_character_),
    PESO = c(3200L, 2900L, 3100L),
    BRANCOS = c("  ", "x", ""),
    stringsAsFactors = FALSE
  )
}

test_that("resumir_colunas devolve uma linha por coluna", {
  r <- resumir_colunas(amostra_fixture())
  expect_equal(nrow(r), 5L)
  expect_equal(r$Variavel, c("DTOBITO", "SEXO", "VAZIA", "PESO", "BRANCOS"))
})

test_that("resumir_colunas calcula o percentual preenchido", {
  r <- resumir_colunas(amostra_fixture())
  expect_equal(r$Preenchido[r$Variavel == "SEXO"], "100%")
  expect_equal(r$Preenchido[r$Variavel == "DTOBITO"], "67%")
  expect_equal(r$Preenchido[r$Variavel == "VAZIA"], "0%")
})

test_that("strings só de espaço contam como não preenchidas", {
  r <- resumir_colunas(amostra_fixture())
  expect_equal(r$Preenchido[r$Variavel == "BRANCOS"], "33%")
})

test_that("resumir_colunas traduz os tipos", {
  r <- resumir_colunas(amostra_fixture())
  expect_equal(r$Tipo[r$Variavel == "PESO"], "inteiro")
  expect_equal(r$Tipo[r$Variavel == "SEXO"], "texto")
})

test_that("resumir_colunas limita a quantidade de exemplos", {
  df <- data.frame(X = as.character(1:10), stringsAsFactors = FALSE)
  r <- resumir_colunas(df, n_exemplos = 3L)
  expect_equal(r$Exemplos, "1, 2, 3")
})

test_that("resumir_colunas aguenta data.frame vazio", {
  r <- resumir_colunas(data.frame())
  expect_equal(nrow(r), 0L)
  expect_true(all(c("Variavel", "Tipo", "Preenchido", "Exemplos") %in% names(r)))
})

test_that("anotar_descricoes acrescenta a curadoria quando existe", {
  r <- anotar_descricoes(resumir_colunas(amostra_fixture()))
  expect_equal(r$Descricao[r$Variavel == "DTOBITO"], "Data do óbito")
  expect_equal(r$Descricao[r$Variavel == "PESO"], "Peso ao nascer, em gramas")
})

test_that("variável sem curadoria fica com descrição vazia, não NA", {
  r <- anotar_descricoes(resumir_colunas(amostra_fixture()))
  expect_equal(r$Descricao[r$Variavel == "VAZIA"], "")
  expect_false(any(is.na(r$Descricao)))
})

test_that("a ordem das colunas do dicionário é estável", {
  r <- anotar_descricoes(resumir_colunas(amostra_fixture()))
  expect_equal(names(r), c("Variavel", "Descricao", "Tipo", "Preenchido", "Exemplos"))
})

test_that("o lookup de descrições não tem nomes repetidos", {
  expect_false(any(duplicated(names(descricoes_variaveis))))
})

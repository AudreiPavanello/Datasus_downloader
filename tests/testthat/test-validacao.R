test_that("validar_periodo aceita um período coerente", {
  expect_null(validar_periodo(2020, 2023))
  expect_null(validar_periodo(2023, 2023))
})

test_that("validar_periodo rejeita ano invertido", {
  expect_match(validar_periodo(2024, 2020), "ano inicial")
})

test_that("validar_periodo rejeita ano no futuro", {
  futuro <- as.integer(format(Sys.Date(), "%Y")) + 1L
  expect_match(validar_periodo(2020, futuro), "não pode ser maior")
})

test_that("validar_periodo não tem piso de ano fixo", {
  # O microdatasus >= 3.0.0 usa limites históricos por sistema; travar 1996
  # aqui barrava o SIM, que começa bem antes.
  expect_null(validar_periodo(1979, 1980))
})

test_that("validar_periodo cobra meses em sistema mensal", {
  expect_match(validar_periodo(2023, 2023, mensal = TRUE), "mês inicial")
  expect_null(validar_periodo(2023, 2023, mensal = TRUE, mes_inicio = 1, mes_fim = 12))
})

test_that("mês invertido só é erro dentro do mesmo ano", {
  expect_match(
    validar_periodo(2023, 2023, mensal = TRUE, mes_inicio = 10, mes_fim = 2),
    "mês inicial"
  )
  # Outubro de 2022 a fevereiro de 2023 é um intervalo válido.
  expect_null(validar_periodo(2022, 2023, mensal = TRUE, mes_inicio = 10, mes_fim = 2))
})

test_that("validar_periodo lida com entrada vazia do numericInput", {
  expect_match(validar_periodo(NA, 2023), "Informe o ano")
  expect_match(validar_periodo("", ""), "Informe o ano")
  # numericInput vazio chega como NULL, não como NA.
  expect_match(validar_periodo(NULL, 2023), "Informe o ano")
  expect_match(validar_periodo(2023, NULL), "Informe o ano")
})

test_that("validar_periodo não quebra com mês NULL em sistema mensal", {
  # selectInput não inicializado chega como NULL; antes isso levantava
  # "missing value where TRUE/FALSE needed" em vez de devolver a mensagem.
  expect_match(validar_periodo(2023, 2023, mensal = TRUE, mes_inicio = NULL, mes_fim = 12),
               "Informe o mês")
  expect_match(validar_periodo(2023, 2023, mensal = TRUE, mes_inicio = 1, mes_fim = NULL),
               "Informe o mês")
  expect_match(validar_periodo(2023, 2023, mensal = TRUE, mes_inicio = character(0), mes_fim = character(0)),
               "Informe o mês")
})

test_that("escalar_valido distingue vazio de valor", {
  expect_true(escalar_valido(1L))
  expect_false(escalar_valido(NULL))
  expect_false(escalar_valido(NA))
  expect_false(escalar_valido(integer(0)))
  expect_false(escalar_valido(c(1L, 2L)))
})

test_that("formatar_numero usa o padrão brasileiro sem avisar", {
  expect_equal(formatar_numero(1234567L), "1.234.567")
  expect_equal(formatar_numero(NULL), "--")
})

test_that("validar_ufs exige seleção, salvo Brasil inteiro", {
  expect_match(validar_ufs(character(0)), "ao menos um estado")
  expect_null(validar_ufs(character(0), todas = TRUE))
  expect_null(validar_ufs(c("SP", "RJ")))
  expect_match(validar_ufs("XX"), "inválido")
})

test_that("checar_limite_xlsx só reclama acima do limite do Excel", {
  expect_null(checar_limite_xlsx(1000))
  expect_null(checar_limite_xlsx(LIMITE_XLSX))
  expect_match(checar_limite_xlsx(LIMITE_XLSX + 1), "Excel")
  expect_null(checar_limite_xlsx(NA))
})

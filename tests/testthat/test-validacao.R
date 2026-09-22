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

# ---- Reaproveitamento da sonda --------------------------------------------

recorte <- function(..., sistema = "SIM-DO", ufs = "SP", todas_ufs = FALSE,
                    ano_inicio = 2023, ano_fim = 2023, mensal = FALSE,
                    mes_inicio = 0L, mes_fim = 0L) {
  list(sistema = sistema, ufs = ufs, todas_ufs = todas_ufs,
       ano_inicio = ano_inicio, ano_fim = ano_fim, mensal = mensal,
       mes_inicio = mes_inicio, mes_fim = mes_fim)
}

meta_anual <- list(sistema = "SIM-DO", uf = "SP", ano = 2023, mes = 0L)
meta_mensal <- list(sistema = "SIA-PA", uf = "SP", ano = 2024, mes = 3L)

test_that("uma UF e um ano num sistema anual já estão cobertos pela sonda", {
  # É o caso que motivou a correção: a sonda baixa o arquivo inteiro de SP/2023
  # e, sem isto, o passo 2 baixava o mesmo arquivo de novo.
  expect_true(sonda_cobre_recorte(recorte(), meta_anual))
})

test_that("um único mês igual ao sondado está coberto", {
  p <- recorte(sistema = "SIA-PA", ano_inicio = 2024, ano_fim = 2024,
               mensal = TRUE, mes_inicio = 3L, mes_fim = 3L)
  expect_true(sonda_cobre_recorte(p, meta_mensal))
})

test_that("Brasil inteiro nunca está coberto", {
  expect_false(sonda_cobre_recorte(recorte(ufs = "all", todas_ufs = TRUE), meta_anual))
  expect_false(sonda_cobre_recorte(recorte(ufs = "all"), meta_anual))
})

test_that("mais de uma UF não está coberta", {
  expect_false(sonda_cobre_recorte(recorte(ufs = c("SP", "RJ")), meta_anual))
})

test_that("UF diferente da sondada não está coberta", {
  expect_false(sonda_cobre_recorte(recorte(ufs = "RJ"), meta_anual))
})

test_that("intervalo de mais de um ano não está coberto", {
  expect_false(sonda_cobre_recorte(recorte(ano_inicio = 2022, ano_fim = 2023), meta_anual))
})

test_that("ano diferente do sondado não está coberto", {
  expect_false(sonda_cobre_recorte(recorte(ano_inicio = 2022, ano_fim = 2022), meta_anual))
})

test_that("período mensal de jan a dez não está coberto pela sonda de um mês", {
  p <- recorte(sistema = "SIA-PA", ano_inicio = 2024, ano_fim = 2024,
               mensal = TRUE, mes_inicio = 1L, mes_fim = 12L)
  expect_false(sonda_cobre_recorte(p, meta_mensal))
})

test_that("mês único diferente do sondado não está coberto", {
  p <- recorte(sistema = "SIA-PA", ano_inicio = 2024, ano_fim = 2024,
               mensal = TRUE, mes_inicio = 5L, mes_fim = 5L)
  expect_false(sonda_cobre_recorte(p, meta_mensal))
})

test_that("sistema diferente do sondado não está coberto", {
  expect_false(sonda_cobre_recorte(recorte(sistema = "SINASC"), meta_anual))
})

test_that("sem sonda não há cobertura", {
  expect_false(sonda_cobre_recorte(recorte(), NULL))
  expect_false(sonda_cobre_recorte(NULL, meta_anual))
})

test_that("ano vazio não é tratado como cobertura", {
  expect_false(sonda_cobre_recorte(recorte(ano_inicio = NULL, ano_fim = NULL), meta_anual))
})

test_that("chave_sonda distingue os recortes", {
  expect_equal(chave_sonda("SIM-DO", "SP", 2023, 0L), "SIM-DO|SP|2023|0")
  expect_false(identical(chave_sonda("SIA-PA", "SP", 2024, 1L),
                         chave_sonda("SIA-PA", "SP", 2024, 2L)))
})

test_that("o rótulo do botão diz o que vai acontecer", {
  expect_equal(rotulo_botao_baixar(0L), "Baixar tudo")
  expect_equal(rotulo_botao_baixar(NULL), "Baixar tudo")
  expect_equal(rotulo_botao_baixar(1L), "Baixar 1 coluna")
  expect_equal(rotulo_botao_baixar(5L), "Baixar 5 colunas")
})

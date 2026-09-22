test_that("nome_arquivo monta o padrão anual", {
  n <- nome_arquivo("SIM-DO", "SP", 2023, 2023, ext = "csv",
                    agora = as.POSIXct("2026-09-22 14:30:00", tz = "UTC"))
  expect_equal(n, "datasus_sim-do_SP_2023_2023_20260922-1430.csv")
})

test_that("nome_arquivo monta o padrão mensal com zero à esquerda", {
  n <- nome_arquivo("SIA-PA", "SP", 2024, 2024, mes_inicio = 1, mes_fim = 12,
                    ext = "parquet",
                    agora = as.POSIXct("2026-09-22 14:30:00", tz = "UTC"))
  expect_equal(n, "datasus_sia-pa_SP_2024-01_2024-12_20260922-1430.parquet")
})

test_that("nome_arquivo colapsa poucas UFs e resume muitas", {
  agora <- as.POSIXct("2026-09-22 14:30:00", tz = "UTC")
  expect_match(nome_arquivo("SIM-DO", c("SP", "RJ"), 2023, 2023, agora = agora), "_SP-RJ_")
  expect_match(
    nome_arquivo("SIM-DO", c("SP", "RJ", "MG", "ES", "BA"), 2023, 2023, agora = agora),
    "_5uf_"
  )
})

test_that("nome_arquivo marca o Brasil inteiro", {
  agora <- as.POSIXct("2026-09-22 14:30:00", tz = "UTC")
  expect_match(nome_arquivo("SIM-DO", "all", 2023, 2023, agora = agora), "_todos_")
  expect_match(
    nome_arquivo("SIM-DO", c("SP"), 2023, 2023, todas_ufs = TRUE, agora = agora),
    "_todos_"
  )
})

test_that("formatar_bytes escolhe a unidade", {
  expect_equal(formatar_bytes(512), "512.0 B")
  expect_equal(formatar_bytes(1024), "1.0 KB")
  expect_equal(formatar_bytes(1024^2 * 3), "3.0 MB")
  expect_equal(formatar_bytes(1024^3), "1.0 GB")
  expect_equal(formatar_bytes(NA), "--")
  expect_equal(formatar_bytes(0), "0.0 B")
})

test_that("descrever_periodo encurta o caso de ano único", {
  expect_equal(descrever_periodo(2023, 2023), "2023")
  expect_equal(descrever_periodo(2020, 2023), "2020 a 2023")
  expect_equal(
    descrever_periodo(2024, 2024, mensal = TRUE, mes_inicio = 1, mes_fim = 12),
    "01/2024 a 12/2024"
  )
})

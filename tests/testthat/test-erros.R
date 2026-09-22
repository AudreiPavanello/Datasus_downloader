test_that("traduzir_erro reconhece timeout", {
  expect_match(traduzir_erro("Error: operation timed out after 240s"), "demorou demais")
})

test_that("traduzir_erro reconhece falha de rede", {
  expect_match(traduzir_erro("cannot open URL 'ftp://ftp.datasus.gov.br'"), "conectar ao DATASUS")
})

test_that("traduzir_erro reconhece recorte inexistente", {
  expect_match(traduzir_erro("No files found for this period"), "Não há arquivos")
})

test_that("traduzir_erro devolve a mensagem original quando não reconhece", {
  expect_match(traduzir_erro("algo muito específico deu errado"), "algo muito espec")
})

test_that("traduzir_erro nunca devolve vazio", {
  expect_true(nzchar(traduzir_erro("")))
  expect_true(nzchar(traduzir_erro(character(0))))
})

test_that("mensagem_segura escapa HTML", {
  # O código antigo injetava e$message direto no DOM via shinyjs::html().
  escapado <- mensagem_segura("<script>alert('x')</script>")
  expect_false(grepl("<script>", escapado, fixed = TRUE))
  expect_match(escapado, "&lt;script&gt;")
})

test_that("mensagem_segura remove cores ANSI do cli", {
  expect_equal(mensagem_segura("\033[31mfalhou\033[0m"), "falhou")
})

test_that("mensagem_segura trunca mensagens longas", {
  longa <- paste(rep("a", 900), collapse = "")
  expect_lte(nchar(mensagem_segura(longa)), 404L)
})

test_that("escapar_html cobre os cinco caracteres", {
  expect_equal(escapar_html("<>&\"'"), "&lt;&gt;&amp;&quot;&#39;")
})

test_that("escapar_html escapa o & antes dos demais", {
  expect_equal(escapar_html("&lt;"), "&amp;lt;")
})

test_that("o catálogo tem o número de layouts da versão 3.0.0 do microdatasus", {
  expect_equal(sum(sistemas$familia == "SIM"), 5L)
  expect_equal(sum(sistemas$familia == "SINASC"), 1L)
  expect_equal(sum(sistemas$familia == "SIH"), 4L)
  expect_equal(sum(sistemas$familia == "SIA"), 12L)
  expect_equal(sum(sistemas$familia == "CNES"), 13L)
  expect_equal(sum(sistemas$familia == "SINAN"), 8L)
  expect_equal(nrow(sistemas), 43L)
})

test_that("não há ids repetidos", {
  expect_false(any(duplicated(sistemas$id)))
})

test_that("toda família do seletor existe no catálogo", {
  expect_true(all(familias %in% sistemas$familia))
  expect_setequal(unname(familias), unique(sistemas$familia))
})

test_that("layouts_da_familia devolve um vetor nomeado utilizável no selectInput", {
  sia <- layouts_da_familia("SIA")
  expect_length(sia, 12L)
  expect_true("SIA-PA" %in% sia)
  expect_true(all(nzchar(names(sia))))
})

test_that("a coluna mensal reflete a periodicidade real dos sistemas", {
  expect_true(all(sistemas$mensal[sistemas$familia %in% c("SIH", "SIA", "CNES")]))
  expect_false(any(sistemas$mensal[sistemas$familia %in% c("SIM", "SINASC", "SINAN")]))
})

test_that("eh_mensal concorda com o catálogo", {
  expect_true(eh_mensal("SIA-PA"))
  expect_false(eh_mensal("SIM-DO"))
  expect_false(eh_mensal("inexistente"))
})

test_that("só os layouts documentados têm processador", {
  # process_sih, process_sia e process_cnes cobrem apenas parte da família.
  com_proc <- sistemas$id[!is.na(sistemas$processador)]
  expect_true("SIH-RD" %in% com_proc)
  expect_false("SIH-SP" %in% com_proc)
  expect_true("SIA-PA" %in% com_proc)
  expect_false("SIA-AQ" %in% com_proc)
  expect_setequal(intersect(com_proc, layouts_da_familia("CNES")), c("CNES-ST", "CNES-PF"))
  # Leptospirose é o único SINAN sem função de processamento.
  expect_false("SINAN-LEPTOSPIROSE" %in% com_proc)
})

test_that("proc_sis marca exatamente os processadores que pedem information_system", {
  pedem <- sistemas$id[sistemas$proc_sis]
  expect_setequal(pedem, c("SIH-RD", "SIA-PA", "CNES-ST", "CNES-PF"))
  expect_true(all(!is.na(sistemas$processador[sistemas$proc_sis])))
})

test_that("sistema_info devolve a linha certa ou NULL", {
  info <- sistema_info("SIA-PA")
  expect_equal(info$familia, "SIA")
  expect_true(info$mensal)
  expect_equal(info$processador, "process_sia")
  expect_null(sistema_info("NAO-EXISTE"))
  expect_null(sistema_info(NULL))
})

test_that("todo processador citado existe mesmo no microdatasus", {
  skip_if_not_installed("microdatasus")
  exportados <- getNamespaceExports("microdatasus")
  citados <- unique(stats::na.omit(sistemas$processador))
  expect_true(all(citados %in% exportados))
})

test_that("os 27 estados estão presentes", {
  expect_length(estados, 27L)
  expect_false(any(duplicated(estados)))
})

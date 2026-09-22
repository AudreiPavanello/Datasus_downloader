# Acesso ao DATASUS.
#
# Todo o trabalho de rede roda em daemons do mirai, fora do processo principal
# do Shiny. Isso importa porque no shinyapps.io um processo R atende várias
# sessões: com a chamada bloqueante que existia antes, um download longo
# congelava todos os usuários daquele processo.
#
# Os daemons não herdam o ambiente global, então as expressões abaixo são
# autocontidas: só usam `microdatasus::` e as variáveis passadas por argumento.
# Nenhuma função deste repositório é referenciada lá dentro.

# ---- Sonda ----------------------------------------------------------------

# Baixa a menor fatia possível do recorte (uma UF, o ano inicial e, para
# sistemas mensais, só o mês inicial). Serve para listar as colunas antes do
# download de verdade, que é o que permite usar `vars` e não trazer o layout
# inteiro.
#
# A sonda nunca aplica process_*: `vars` opera sobre os nomes brutos do DBC, e
# é essa lista que o usuário precisa ver.
# Construtor, não um objeto pronto: cada sessão precisa da sua própria tarefa.
# Um ExtendedTask criado no escopo global seria compartilhado por todos os
# usuários, que passariam a ver o status e o resultado uns dos outros.
nova_tarefa_sonda <- function() shiny::ExtendedTask$new(function(p) {
  mirai::mirai(
    {
      dados <- microdatasus::fetch_datasus(
        year_start = ano,
        year_end = ano,
        month_start = if (mes == 0L) NULL else mes,
        month_end = if (mes == 0L) NULL else mes,
        uf = uf,
        information_system = sis,
        timeout = tmo,
        stop_on_error = FALSE,
        quiet = TRUE
      )

      if (is.null(dados)) dados <- data.frame()

      list(
        colunas = names(dados),
        amostra = utils::head(as.data.frame(dados), 200L),
        n = nrow(dados)
      )
    },
    ano = p$ano, mes = p$mes, uf = p$uf, sis = p$sistema, tmo = p$timeout
  )
})

# ---- Download completo ----------------------------------------------------

# Devolve o caminho de um .rds gravado pelo daemon, mais metadados e as 200
# primeiras linhas. O dado completo nunca entra no processo principal: é isso
# que evita o estouro de memória do reactiveVal antigo em SIA-PA e SIH de
# estados grandes. O downloadHandler lê o arquivo só no clique.
# Idem: construído por sessão, dentro do moduleServer.
nova_tarefa_download <- function() shiny::ExtendedTask$new(function(p) {
  mirai::mirai(
    {
      dados <- microdatasus::fetch_datasus(
        year_start = ano_i,
        year_end = ano_f,
        month_start = if (mes_i == 0L) NULL else mes_i,
        month_end = if (mes_f == 0L) NULL else mes_f,
        uf = ufs,
        information_system = sis,
        vars = if (length(colunas) == 0L) NULL else colunas,
        timeout = tmo,
        stop_on_error = soe,
        track_source = trk,
        quiet = TRUE
      )

      if (is.null(dados)) dados <- data.frame()

      rotulado <- FALSE
      aviso <- NA_character_

      # `vars` pode ter removido colunas que o processador espera recodificar.
      # Nesse caso não falhamos: devolvemos o dado bruto e avisamos na UI.
      if (!is.na(proc) && nrow(dados) > 0L) {
        f <- getExportedValue("microdatasus", proc)
        argumentos <- list(dados, municipality_data = muni)
        if (isTRUE(psis)) argumentos$information_system <- sis
        if (identical(proc, "process_sia")) {
          argumentos$nome_proced <- lookup
          argumentos$nome_ocupacao <- lookup
        }
        if (identical(proc, "process_cnes")) {
          argumentos$nomes <- lookup
        }

        resultado <- tryCatch(do.call(f, argumentos), error = function(e) e)
        if (inherits(resultado, "error")) {
          aviso <- conditionMessage(resultado)
        } else {
          dados <- resultado
          rotulado <- TRUE
        }
      }

      caminho <- tempfile(pattern = "datasus_", fileext = ".rds")
      saveRDS(dados, caminho, compress = FALSE)

      list(
        caminho = caminho,
        nrow = nrow(dados),
        ncol = ncol(dados),
        colunas = names(dados),
        amostra = utils::head(as.data.frame(dados), 200L),
        bytes = file.size(caminho),
        rotulado = rotulado,
        aviso = aviso
      )
    },
    ano_i = p$ano_inicio, ano_f = p$ano_fim,
    mes_i = p$mes_inicio, mes_f = p$mes_fim,
    ufs = p$ufs, sis = p$sistema, colunas = p$vars,
    tmo = p$timeout, soe = p$stop_on_error, trk = p$track_source,
    proc = p$processador, psis = p$proc_sis,
    muni = p$municipality_data, lookup = p$lookups
  )
})

# ---- Gravação dos formatos ------------------------------------------------

#' Formatos de saída disponíveis nesta instalação.
#'
#' Parquet só aparece se o arrow estiver instalado; ele não é dependência
#' obrigatória por causa do tamanho do binário no deploy.
formatos_disponiveis <- function() {
  escolhas <- c(
    "CSV (UTF-8, abre no Excel)" = "csv",
    "Excel (xlsx)" = "xlsx",
    "R (rds)" = "rds"
  )
  if (requireNamespace("arrow", quietly = TRUE)) {
    escolhas <- c(escolhas, "Parquet" = "parquet")
  }
  escolhas
}

#' Converte o .rds intermediário para o formato pedido.
gravar_como <- function(caminho_rds, destino, formato) {
  if (identical(formato, "rds")) {
    file.copy(caminho_rds, destino, overwrite = TRUE)
    return(invisible(destino))
  }

  dados <- readRDS(caminho_rds)

  switch(formato,
    # write_excel_csv grava UTF-8 com BOM, que é o que faz o Excel no Windows
    # mostrar os acentos corretamente. O write.csv() antigo não fazia isso.
    "csv" = readr::write_excel_csv(dados, destino, na = ""),
    "xlsx" = writexl::write_xlsx(dados, destino),
    "parquet" = arrow::write_parquet(dados, destino),
    stop("Formato não suportado: ", formato)
  )

  invisible(destino)
}

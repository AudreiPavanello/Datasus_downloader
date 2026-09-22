# Funções puras, sem reatividade e sem rede.
#
# Tudo aqui é testável com `testthat::test_dir("tests/testthat")` sem depender
# do FTP do DATASUS. A regra é: se precisa de rede ou de `session`, não mora
# neste arquivo.

# ---- Catálogo -------------------------------------------------------------

#' Devolve a linha do catálogo de um sistema, ou NULL se não existir.
sistema_info <- function(id) {
  if (is.null(id) || !nzchar(id)) return(NULL)
  i <- match(id, sistemas$id)
  if (is.na(i)) return(NULL)
  as.list(sistemas[i, ])
}

#' Layouts de uma família, como vetor nomeado (rótulo -> id) para selectInput.
layouts_da_familia <- function(familia) {
  linhas <- sistemas[sistemas$familia == familia, ]
  stats::setNames(linhas$id, linhas$rotulo)
}

#' TRUE quando o sistema exige seleção de meses.
eh_mensal <- function(id) {
  info <- sistema_info(id)
  !is.null(info) && isTRUE(info$mensal)
}

# ---- Validação ------------------------------------------------------------

#' Valida o período pedido.
#'
#' Devolve NULL quando está tudo certo, ou uma mensagem em português.
#'
#' Não há piso de ano aqui de propósito: o microdatasus >= 3.0.0 tem limites
#' históricos por sistema e é a autoridade sobre isso. Deixamos o pacote
#' levantar o erro e exibimos a mensagem dele.
validar_periodo <- function(ano_inicio, ano_fim, mensal = FALSE,
                            mes_inicio = NULL, mes_fim = NULL) {
  ano_inicio <- suppressWarnings(as.integer(ano_inicio))
  ano_fim <- suppressWarnings(as.integer(ano_fim))

  if (!escalar_valido(ano_inicio) || !escalar_valido(ano_fim)) {
    return("Informe o ano inicial e o ano final.")
  }
  if (ano_inicio > ano_fim) {
    return("O ano inicial deve ser menor ou igual ao ano final.")
  }

  ano_corrente <- as.integer(format(Sys.Date(), "%Y"))
  if (ano_fim > ano_corrente) {
    return(sprintf("O ano final não pode ser maior que %d.", ano_corrente))
  }

  if (isTRUE(mensal)) {
    mes_inicio <- suppressWarnings(as.integer(mes_inicio))
    mes_fim <- suppressWarnings(as.integer(mes_fim))

    if (!escalar_valido(mes_inicio) || !escalar_valido(mes_fim)) {
      return("Informe o mês inicial e o mês final.")
    }
    if (ano_inicio == ano_fim && mes_inicio > mes_fim) {
      return("Dentro do mesmo ano, o mês inicial deve ser menor ou igual ao mês final.")
    }
  }

  NULL
}

#' Valida a seleção de estados.
validar_ufs <- function(ufs, todas = FALSE) {
  if (isTRUE(todas)) return(NULL)
  if (length(ufs) == 0) return("Selecione ao menos um estado.")
  desconhecidas <- setdiff(ufs, unname(estados))
  if (length(desconhecidas) > 0) {
    return(sprintf("Estado inválido: %s.", paste(desconhecidas, collapse = ", ")))
  }
  NULL
}

#' Mensagem quando o recorte não cabe numa planilha do Excel, ou NULL.
checar_limite_xlsx <- function(n_linhas) {
  if (!escalar_valido(n_linhas)) return(NULL)
  if (n_linhas <= LIMITE_XLSX) return(NULL)
  sprintf(
    paste0("O recorte tem %s linhas e o Excel aceita no máximo %s. ",
           "Escolha CSV, Parquet ou RDS, ou reduza o período."),
    formatar_numero(n_linhas), formatar_numero(LIMITE_XLSX)
  )
}

# ---- Nomes e formatação ---------------------------------------------------

#' Monta o nome do arquivo baixado.
nome_arquivo <- function(sistema, ufs, ano_inicio, ano_fim,
                         mes_inicio = NULL, mes_fim = NULL,
                         ext = "csv", todas_ufs = FALSE,
                         agora = Sys.time()) {
  parte_uf <- if (isTRUE(todas_ufs) || identical(ufs, "all")) {
    "todos"
  } else if (length(ufs) > 4) {
    sprintf("%duf", length(ufs))
  } else {
    paste(ufs, collapse = "-")
  }

  mensal <- !is.null(mes_inicio) && !is.null(mes_fim)
  parte_periodo <- if (mensal) {
    sprintf("%04d-%02d_%04d-%02d",
            as.integer(ano_inicio), as.integer(mes_inicio),
            as.integer(ano_fim), as.integer(mes_fim))
  } else {
    sprintf("%04d_%04d", as.integer(ano_inicio), as.integer(ano_fim))
  }

  sprintf("datasus_%s_%s_%s_%s.%s",
          tolower(sistema), parte_uf, parte_periodo,
          format(agora, "%Y%m%d-%H%M"), ext)
}

#' Tamanho legível a partir de bytes.
formatar_bytes <- function(n) {
  if (is.null(n) || is.na(n)) return("--")
  unidades <- c("B", "KB", "MB", "GB", "TB")
  i <- if (n <= 0) 1L else min(length(unidades), floor(log(n, 1024)) + 1L)
  sprintf("%.1f %s", n / 1024^(i - 1L), unidades[i])
}

#' Descreve o período de forma curta, para o value box.
descrever_periodo <- function(ano_inicio, ano_fim, mensal = FALSE,
                              mes_inicio = NULL, mes_fim = NULL) {
  if (isTRUE(mensal) && !is.null(mes_inicio) && !is.null(mes_fim)) {
    sprintf("%02d/%d a %02d/%d",
            as.integer(mes_inicio), as.integer(ano_inicio),
            as.integer(mes_fim), as.integer(ano_fim))
  } else if (identical(as.integer(ano_inicio), as.integer(ano_fim))) {
    as.character(ano_inicio)
  } else {
    sprintf("%s a %s", ano_inicio, ano_fim)
  }
}

# ---- Dicionário gerado ----------------------------------------------------

tipo_legivel <- function(x) {
  switch(class(x)[1],
    "character" = "texto",
    "factor"    = "categoria",
    "integer"   = "inteiro",
    "numeric"   = "numérico",
    "double"    = "numérico",
    "logical"   = "lógico",
    "Date"      = "data",
    class(x)[1]
  )
}

#' Resume as colunas de um data.frame para a aba de dicionário.
#'
#' Devolve nome, tipo, percentual preenchido e exemplos de valores. É isso que
#' substitui o dicionário escrito à mão, que cobria ~10 variáveis por sistema.
resumir_colunas <- function(df, n_exemplos = 3L) {
  if (is.null(df) || ncol(df) == 0) {
    return(data.frame(Variavel = character(), Tipo = character(),
                      Preenchido = character(), Exemplos = character(),
                      stringsAsFactors = FALSE))
  }

  resumo <- lapply(names(df), function(nm) {
    col <- df[[nm]]
    vazio <- is.na(col) | (is.character(col) & trimws(as.character(col)) == "")
    preenchido <- if (length(col) == 0) 0 else 100 * sum(!vazio) / length(col)

    exemplos <- unique(as.character(col[!vazio]))
    exemplos <- utils::head(exemplos[nzchar(exemplos)], n_exemplos)

    data.frame(
      Variavel = nm,
      Tipo = tipo_legivel(col),
      Preenchido = sprintf("%.0f%%", preenchido),
      Exemplos = paste(exemplos, collapse = ", "),
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, resumo)
}

#' Junta o resumo observado com as descrições curadas de R/dictionaries.R.
anotar_descricoes <- function(resumo, lookup = descricoes_variaveis) {
  if (nrow(resumo) == 0) return(resumo)
  desc <- unname(lookup[resumo$Variavel])
  desc[is.na(desc)] <- ""
  cbind(resumo["Variavel"], Descricao = desc,
        resumo[setdiff(names(resumo), "Variavel")],
        stringsAsFactors = FALSE)
}

# ---- Utilitários ----------------------------------------------------------

`%||%` <- function(x, y) if (is.null(x)) y else x

#' TRUE quando x é um único número utilizável.
#'
#' Um numericInput vazio chega como NULL e um selectInput não inicializado como
#' character(0). Sem esta checagem, `is.na(x) || ...` recebe um vetor de
#' comprimento zero e a validação quebra em vez de devolver a mensagem.
escalar_valido <- function(x) {
  length(x) == 1L && !is.na(x)
}

#' Formata inteiros no padrão brasileiro.
#'
#' Passa `decimal.mark` explicitamente porque, com `big.mark = "."` sozinho, o
#' format() avisa que os dois separadores são iguais.
formatar_numero <- function(n) {
  if (!escalar_valido(n)) return("--")
  format(n, big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
}

#' Escapa texto vindo de uma exceção antes de virar HTML.
#'
#' As mensagens do microdatasus são formatadas pelo cli e podem conter markup.
#' O código antigo injetava `e$message` direto no DOM via `shinyjs::html()`.
mensagem_segura <- function(texto, limite = 400L) {
  texto <- paste(as.character(texto), collapse = " ")
  texto <- gsub("\033\\[[0-9;]*m", "", texto)  # remove cores ANSI do cli
  texto <- trimws(texto)
  if (!nzchar(texto)) texto <- "Erro desconhecido."
  if (nchar(texto) > limite) texto <- paste0(substr(texto, 1, limite), "...")
  escapar_html(texto)
}

#' Escapa os caracteres que teriam significado em HTML.
#'
#' Local em vez de `htmltools::htmlEscape()` para que este arquivo continue
#' sendo R base puro e possa ser testado sem carregar o Shiny.
escapar_html <- function(texto) {
  texto <- gsub("&", "&amp;", texto, fixed = TRUE)
  texto <- gsub("<", "&lt;", texto, fixed = TRUE)
  texto <- gsub(">", "&gt;", texto, fixed = TRUE)
  texto <- gsub("\"", "&quot;", texto, fixed = TRUE)
  gsub("'", "&#39;", texto, fixed = TRUE)
}

#' Traduz falhas conhecidas para linguagem de usuário.
#'
#' O app é usado por colegas e alunos que não escrevem R, então uma mensagem
#' como "cannot open URL" ou um traceback do cli não pode chegar à tela. O que
#' não casar com nenhum padrão volta como a mensagem original higienizada, para
#' não esconder informação útil.
traduzir_erro <- function(msg) {
  texto <- paste(as.character(msg), collapse = " ")

  padroes <- list(
    c("timed out|timeout|Timeout",
      "O DATASUS demorou demais para responder. Tente de novo, aumente o tempo limite em Opções avançadas ou reduza o período."),
    c("cannot open URL|Could not resolve|connection|Couldn't connect|network",
      "Não foi possível conectar ao DATASUS. Verifique sua internet e tente de novo em alguns minutos."),
    c("not available|no files|No files|não encontrado|not found|404",
      "Não há arquivos no DATASUS para esse sistema, estado e período. Confira o recorte: muitos sistemas começam bem depois de 1996."),
    c("dbc|DBC",
      "Um dos arquivos baixados veio corrompido. Tente de novo; se persistir, reduza o período para localizar o mês problemático."),
    c("memory|cannot allocate",
      "O recorte é grande demais para a memória disponível. Selecione menos colunas ou baixe um período menor.")
  )

  for (p in padroes) {
    if (grepl(p[1], texto, ignore.case = TRUE)) return(p[2])
  }

  mensagem_segura(texto)
}

# ---- Reaproveitamento da sonda --------------------------------------------

#' Chave de cache de uma sonda.
chave_sonda <- function(sistema, uf, ano, mes) {
  paste(sistema, uf, as.integer(ano), as.integer(mes %||% 0L), sep = "|")
}

#' A sonda já baixou tudo o que o download pediria?
#'
#' A sonda busca uma UF, o ano inicial e, em sistema mensal, só o mês inicial.
#' Quando o recorte pedido é exatamente isso, baixar de novo seria repetir o
#' mesmo arquivo: é o caso comum de um sistema anual com uma UF e um ano, em que
#' a sonda sozinha já custa o download inteiro.
#'
#' `meta` é o recorte que a sonda efetivamente baixou:
#' `list(sistema =, uf =, ano =, mes =)`.
sonda_cobre_recorte <- function(p, meta) {
  if (is.null(meta) || is.null(p)) return(FALSE)

  # "Brasil inteiro" e seleção múltipla nunca são cobertos: a sonda vê uma UF.
  if (isTRUE(p$todas_ufs) || identical(p$ufs, "all")) return(FALSE)
  if (length(p$ufs) != 1L) return(FALSE)
  if (!identical(as.character(p$ufs[1]), as.character(meta$uf))) return(FALSE)

  if (!identical(p$sistema, meta$sistema)) return(FALSE)

  if (!escalar_valido(p$ano_inicio) || !escalar_valido(p$ano_fim)) return(FALSE)
  if (as.integer(p$ano_inicio) != as.integer(p$ano_fim)) return(FALSE)
  if (as.integer(p$ano_inicio) != as.integer(meta$ano)) return(FALSE)

  if (isTRUE(p$mensal)) {
    if (!escalar_valido(p$mes_inicio) || !escalar_valido(p$mes_fim)) return(FALSE)
    if (as.integer(p$mes_inicio) != as.integer(p$mes_fim)) return(FALSE)
    if (as.integer(p$mes_inicio) != as.integer(meta$mes)) return(FALSE)
  }

  TRUE
}

#' Descreve o que o botão de download vai trazer.
#'
#' Fica numa linha abaixo do botão, e não no rótulo dele: `input_task_button()`
#' monta o botão com marcação própria para os estados ocioso e ocupado, e
#' `updateActionButton()` reescreveria esse conteúdo, quebrando o estado
#' "Baixando...". O `update_task_button()` da bslib só troca `state`, não o
#' rótulo.
resumo_selecao_colunas <- function(n_colunas) {
  if (is.null(n_colunas) || n_colunas == 0L) return("Todas as colunas")
  sprintf("%d coluna%s selecionada%s", n_colunas,
          if (n_colunas > 1L) "s" else "", if (n_colunas > 1L) "s" else "")
}

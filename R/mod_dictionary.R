# Aba de dicionário de variáveis.
#
# Antes isto era um `switch` sobre quatro data.frame escritos à mão, com cerca
# de dez variáveis por sistema, contra as centenas que os layouts realmente
# têm. Agora o dicionário é gerado a partir do próprio dado explorado na aba de
# download (nome, tipo, quanto está preenchido, exemplos de valores) e as
# descrições curadas de R/dictionaries.R entram por cima, quando existem.

mod_dictionary_ui <- function(id) {
  ns <- shiny::NS(id)

  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 320,
      title = "Dicionário",
      shiny::p(
        class = "text-muted small",
        "As variáveis abaixo são lidas do conjunto que você explorou na aba",
        shiny::strong("Download"), "."
      ),
      shiny::uiOutput(ns("resumo"))
    ),
    bslib::card(
      full_screen = TRUE,
      bslib::card_header("Variáveis disponíveis"),
      DT::DTOutput(ns("tabela"))
    )
  )
}

mod_dictionary_server <- function(id, sonda) {
  shiny::moduleServer(id, function(input, output, session) {

    tabela <- shiny::reactive({
      s <- sonda()
      if (is.null(s) || length(s$colunas) == 0) return(NULL)
      anotar_descricoes(resumir_colunas(s$amostra))
    })

    output$resumo <- shiny::renderUI({
      t <- tabela()
      if (is.null(t)) {
        return(alerta_ui("info", paste(
          "Nenhum conjunto explorado ainda. Vá em <strong>Download</strong>,",
          "escolha um recorte e clique em <em>Escolher colunas</em>."
        )))
      }
      com_descricao <- sum(nzchar(t$Descricao))
      shiny::tagList(
        shiny::p(shiny::strong(nrow(t)), "variáveis encontradas."),
        shiny::p(class = "text-muted small",
                 sprintf("%d com descrição curada.", com_descricao))
      )
    })

    output$tabela <- DT::renderDT({
      t <- tabela()
      shiny::validate(shiny::need(
        !is.null(t),
        "Clique em 'Escolher colunas' na aba Download para ver o dicionário deste conjunto."
      ))
      DT::datatable(
        t,
        rownames = FALSE,
        colnames = c("Variável", "Descrição", "Tipo", "Preenchido", "Exemplos"),
        options = list(pageLength = 25, scrollX = TRUE,
                       language = list(url = "//cdn.datatables.net/plug-ins/1.13.6/i18n/pt-BR.json"))
      )
    })
  })
}

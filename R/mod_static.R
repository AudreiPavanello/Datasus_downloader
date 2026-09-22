# Abas estáticas: instruções e informações sobre os sistemas.

mod_instrucoes_ui <- function() {
  bslib::layout_columns(
    col_widths = c(7, 5),

    bslib::card(
      bslib::card_header("Como usar"),
      bslib::card_body(
        shiny::tags$ol(
          class = "ps-3",
          shiny::tags$li(shiny::strong("Escolha o sistema e o conjunto de dados."),
                         " O sistema é a base (mortalidade, nascimentos, internações);",
                         " o conjunto é o layout específico dentro dela."),
          shiny::tags$li(shiny::strong("Defina estado e período."),
                         " Sistemas mensais mostram também os seletores de mês."),
          shiny::tags$li(shiny::strong("Clique em 'Explorar colunas'."),
                         " O app baixa uma fatia mínima só para descobrir quais",
                         " colunas existem naquele conjunto."),
          shiny::tags$li(shiny::strong("Selecione as colunas que interessam."),
                         " Este é o passo que mais economiza tempo: o download",
                         " seguinte lê apenas elas."),
          shiny::tags$li(shiny::strong("Clique em 'Preparar download'."),
                         " Agora sim o período inteiro é baixado."),
          shiny::tags$li(shiny::strong("Escolha o formato e salve."))
        )
      )
    ),

    shiny::tagList(
      bslib::card(
        bslib::card_header("Por que escolher colunas antes"),
        bslib::card_body(
          shiny::p(
            "Os arquivos do DATASUS têm layouts largos: a produção ambulatorial",
            "(SIA-PA) passa de uma centena de colunas, e um ano inteiro são doze",
            "arquivos."
          ),
          shiny::p(
            "Selecionando as colunas antes, o microdatasus lê só elas de cada",
            "arquivo, em vez de carregar tudo e descartar depois. Em recortes",
            "grandes a diferença é de ordens de grandeza, em tempo e em memória."
          )
        )
      ),
      bslib::card(
        bslib::card_header("Dicas"),
        bslib::card_body(
          shiny::tags$ul(
            class = "ps-3 mb-0",
            shiny::tags$li("Períodos longos de SIA e SIH são pesados; comece por um ano."),
            shiny::tags$li(shiny::strong("Aplicar rótulos"), " troca códigos por texto legível, mas deixa o processo mais lento."),
            shiny::tags$li(shiny::strong("Nomes de procedimentos"), " baixa tabelas extras do DATASUS; deixe desligado se não precisar."),
            shiny::tags$li("Para planilhas acima de um milhão de linhas, use CSV ou Parquet: o Excel não abre."),
            shiny::tags$li("Cada sistema tem um ano inicial diferente. Se o período não existir, o app avisa.")
          )
        )
      )
    )
  )
}

mod_sobre_ui <- function() {
  info <- function(titulo, texto, n) {
    bslib::card(
      bslib::card_header(titulo),
      bslib::card_body(
        shiny::p(texto),
        shiny::span(class = "badge text-bg-secondary",
                    sprintf("%d conjunto%s", n, if (n > 1) "s" else ""))
      )
    )
  }

  n_de <- function(f) sum(sistemas$familia == f)

  shiny::tagList(
    bslib::layout_columns(
      col_widths = c(4, 4, 4),
      info("SIM", "Sistema de Informações sobre Mortalidade. Declarações de óbito, com causa básica em CID-10, local, data e dados demográficos.", n_de("SIM")),
      info("SINASC", "Sistema de Informações sobre Nascidos Vivos. Dados da mãe, da gestação e do recém-nascido.", n_de("SINASC")),
      info("SIH", "Sistema de Informações Hospitalares. Internações financiadas pelo SUS, com procedimento, diagnóstico e valores.", n_de("SIH"))
    ),
    bslib::layout_columns(
      col_widths = c(4, 4, 4),
      info("SIA", "Sistema de Informações Ambulatoriais. Produção ambulatorial, APAC e RAAS.", n_de("SIA")),
      info("CNES", "Cadastro Nacional de Estabelecimentos de Saúde. Estabelecimentos, leitos, equipamentos, profissionais e equipes.", n_de("CNES")),
      info("SINAN", "Sistema de Informação de Agravos de Notificação. Arboviroses, malária, Chagas, leishmanioses e leptospirose.", n_de("SINAN"))
    ),
    bslib::card(
      bslib::card_header("Créditos"),
      bslib::card_body(
        shiny::p(
          "Este app é uma interface para o pacote",
          shiny::a("microdatasus", href = "https://github.com/rfsaldanha/microdatasus", target = "_blank"),
          ", de Raphael Saldanha, que faz todo o trabalho de download e tratamento."
        ),
        shiny::p(
          class = "text-muted small mb-0",
          "Saldanha, R. F., Bastos, R. R., & Barcellos, C. (2019). Microdatasus: pacote para download e",
          "pré-processamento de microdados do Departamento de Informática do SUS (DATASUS).",
          shiny::em("Cadernos de Saúde Pública"), ", 35(9), e00032419."
        )
      )
    )
  )
}

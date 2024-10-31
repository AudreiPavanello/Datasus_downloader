# UI Modules for each tab
downloadTabUI <- function(id) {
  ns <- NS(id)
  
  layout_sidebar(
    sidebar = sidebar(
      title = "Opções de Download",
      
      selectInput(ns("sistema"), "Sistema de Informação:",
                  choices = info_systems),
      
      selectInput(ns("estado"), "Estado:",
                  choices = estados),
      
      numericInput(ns("ano_inicio"), "Ano Inicial:",
                   value = 2023, min = 1996, max = 2023),
      
      numericInput(ns("ano_fim"), "Ano Final:",
                   value = 2023, min = 1996, max = 2023),
      
      conditionalPanel(
        condition = sprintf("input['%s'] == 'SIH-RD' || input['%s'] == 'SIA-PA'", 
                            ns("sistema"), ns("sistema")),
        selectInput(ns("mes_inicio"), "Mês Inicial:",
                    choices = meses,
                    selected = 1),
        selectInput(ns("mes_fim"), "Mês Final:",
                    choices = meses,
                    selected = 12)
      ),
      
      actionButton(ns("preview"), "Visualizar Dados", class = "btn-primary"),
      
      conditionalPanel(
        condition = sprintf("output['%s']", ns("data_loaded")),
        hr(),
        selectInput(ns("selected_columns"), "Selecionar Colunas:",
                    choices = NULL,
                    multiple = TRUE)
      ),
      
      radioButtons(ns("formato"), "Formato do arquivo:",
                   choices = c("Excel (xlsx)" = "xlsx", "CSV" = "csv"),
                   selected = "xlsx"),
      
      downloadButton(ns("download"), "Baixar Dados"),
      
      div(id = ns("error_message"), style = "color: red;")
    ),
    
    card(
      card_header("Prévia dos Dados"),
      DTOutput(ns("preview_table"))
    )
  )
}

dictionaryTabUI <- function(id) {
  ns <- NS(id)
  
  layout_sidebar(
    sidebar = sidebar(
      selectInput(ns("dict_sistema"), "Selecione o Sistema:",
                  choices = info_systems)
    ),
    card(
      card_header("Descrição das Variáveis"),
      DTOutput(ns("dict_table"))
    )
  )
}
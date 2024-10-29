library(shiny)
library(bslib)
library(microdatasus)
library(dplyr)
library(openxlsx)

# List of available information systems
info_systems <- c(
  "Sistema de Informações sobre Mortalidade (SIM-DO)" = "SIM-DO",
  "Sistema de Informações sobre Nascidos Vivos (SINASC)" = "SINASC",
  "Sistema de Informações Hospitalares (SIH-RD)" = "SIH-RD",
  "Sistema de Informações Ambulatoriais (SIA-PA)" = "SIA-PA"
)

# List of Brazilian states
estados <- c(
  "Acre" = "AC", "Alagoas" = "AL", "Amapá" = "AP", "Amazonas" = "AM",
  "Bahia" = "BA", "Ceará" = "CE", "Distrito Federal" = "DF",
  "Espírito Santo" = "ES", "Goiás" = "GO", "Maranhão" = "MA",
  "Mato Grosso" = "MT", "Mato Grosso do Sul" = "MS", "Minas Gerais" = "MG",
  "Pará" = "PA", "Paraíba" = "PB", "Paraná" = "PR", "Pernambuco" = "PE",
  "Piauí" = "PI", "Rio de Janeiro" = "RJ", "Rio Grande do Norte" = "RN",
  "Rio Grande do Sul" = "RS", "Rondônia" = "RO", "Roraima" = "RR",
  "Santa Catarina" = "SC", "São Paulo" = "SP", "Sergipe" = "SE",
  "Tocantins" = "TO"
)

# List of months in Portuguese with numeric values
meses <- setNames(1:12, c(
  "Janeiro", "Fevereiro", "Março", "Abril",
  "Maio", "Junho", "Julho", "Agosto",
  "Setembro", "Outubro", "Novembro", "Dezembro"
))

ui <- page_sidebar(
  title = "Download de Dados do DATASUS",
  theme = bs_theme(bootswatch = "flatly"),
  
  sidebar = sidebar(
    title = "Opções de Download",
    
    selectInput("sistema", "Sistema de Informação:",
                choices = info_systems),
    
    selectInput("estado", "Estado:",
                choices = estados),
    
    numericInput("ano_inicio", "Ano Inicial:",
                 value = 2023, min = 1996, max = 2023),
    
    numericInput("ano_fim", "Ano Final:",
                 value = 2023, min = 1996, max = 2023),
    
    # Add month inputs that appear only for SIH and SIA
    conditionalPanel(
      condition = "input.sistema == 'SIH-RD' || input.sistema == 'SIA-PA'",
      selectInput("mes_inicio", "Mês Inicial:",
                  choices = meses,
                  selected = 1),
      selectInput("mes_fim", "Mês Final:",
                  choices = meses,
                  selected = 12)
    ),
    
    radioButtons("formato", "Formato do arquivo:",
                 choices = c("Excel (xlsx)" = "xlsx", "CSV" = "csv"),
                 selected = "xlsx"),
    
    downloadButton("download", "Baixar Dados")
  ),
  
  card(
    card_header("Instruções"),
    p("1. Selecione o sistema de informação desejado"),
    p("2. Escolha o estado"),
    p("3. Defina o período (ano inicial e final)"),
    p("4. Para SIH e SIA, selecione também os meses inicial e final"),
    p("5. Selecione o formato do arquivo"),
    p("6. Clique em 'Baixar Dados'"),
    p("Obs: Para períodos longos, o download pode demorar alguns minutos.")
  )
)

server <- function(input, output, session) {
  
  # Reactive expression to fetch and process data
  dados <- reactive({
    # Show a loading message
    withProgress(message = 'Baixando dados...', {
      
      # Different fetch logic based on the system
      if (input$sistema %in% c("SIH-RD", "SIA-PA")) {
        dados_brutos <- fetch_datasus(
          year_start = input$ano_inicio,
          year_end = input$ano_fim,
          month_start = as.numeric(input$mes_inicio),
          month_end = as.numeric(input$mes_fim),
          uf = input$estado,
          information_system = input$sistema
        )
      } else {
        dados_brutos <- fetch_datasus(
          year_start = input$ano_inicio,
          year_end = input$ano_fim,
          uf = input$estado,
          information_system = input$sistema
        )
      }
      
      # Process the data according to the system
      dados_processados <- switch(input$sistema,
                                  "SIM-DO" = process_sim(dados_brutos),
                                  "SINASC" = process_sinasc(dados_brutos),
                                  "SIH-RD" = process_sih(dados_brutos),
                                  "SIA-PA" = process_sia(dados_brutos, 
                                                         information_system = "SIA-PA",
                                                         nome_proced = TRUE,
                                                         nome_ocupacao = TRUE,
                                                         nome_equipe = TRUE,
                                                         municipality_data = TRUE)
      )
      
      return(dados_processados)
    })
  })
  
  # Download handler
  output$download <- downloadHandler(
    filename = function() {
      if (input$sistema %in% c("SIH-RD", "SIA-PA")) {
        paste0("dados_", input$sistema, "_", input$estado, "_",
               input$ano_inicio, ".", as.numeric(input$mes_inicio), "-",
               input$ano_fim, ".", as.numeric(input$mes_fim), ".", input$formato)
      } else {
        paste0("dados_", input$sistema, "_", input$estado, "_",
               input$ano_inicio, "-", input$ano_fim, ".", input$formato)
      }
    },
    content = function(file) {
      if (input$formato == "csv") {
        write.csv(dados(), file, row.names = FALSE)
      } else {
        wb <- createWorkbook()
        addWorksheet(wb, "Dados")
        writeData(wb, "Dados", dados())
        saveWorkbook(wb, file, overwrite = TRUE)
      }
    }
  )
}

shinyApp(ui, server)
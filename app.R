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
                 value = 2013, min = 1996, max = 2023),
    
    numericInput("ano_fim", "Ano Final:",
                 value = 2013, min = 1996, max = 2023),
    
    # Add radio buttons for file format selection
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
    p("4. Selecione o formato do arquivo"),
    p("5. Clique em 'Baixar Dados'"),
    p("Obs: Para períodos longos, o download pode demorar alguns minutos.")
  )
)

server <- function(input, output, session) {
  
  # Reactive expression to fetch and process data
  dados <- reactive({
    # Show a loading message
    withProgress(message = 'Baixando dados...', {
      
      # Fetch the data
      dados_brutos <- fetch_datasus(
        year_start = input$ano_inicio,
        year_end = input$ano_fim,
        uf = input$estado,
        information_system = input$sistema
      )
      
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
      paste0("dados_", input$sistema, "_", input$estado, "_",
             input$ano_inicio, "-", input$ano_fim, ".", input$formato)
    },
    content = function(file) {
      if (input$formato == "csv") {
        write.csv(dados(), file, row.names = FALSE)
      } else {
        # Create a new workbook
        wb <- createWorkbook()
        # Add a worksheet
        addWorksheet(wb, "Dados")
        # Write the data to the worksheet
        writeData(wb, "Dados", dados())
        # Save the workbook
        saveWorkbook(wb, file, overwrite = TRUE)
      }
    }
  )
}

shinyApp(ui, server)
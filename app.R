library(shiny)
library(bslib)
library(microdatasus)
library(dplyr)
library(openxlsx)
library(shinyjs)
library(waiter)
library(DT)

# Source all modules and helper files
source("global.R")
source("R/ui_modules.R")
source("R/server_modules.R")

ui <- page_fluid(
  useShinyjs(),
  useWaiter(),
  
  navset_card_tab(
    title = "Download de Dados do DATASUS",
    
    nav_panel(
      title = "Instruções",
      card(
        card_header("Como usar"),
        tags$ol(
          tags$li("Selecione o sistema de informação desejado"),
          tags$li("Escolha o estado"),
          tags$li("Defina o período (ano inicial e final)"),
          tags$li("Para SIH e SIA, selecione também os meses inicial e final"),
          tags$li("Clique em 'Visualizar Dados' para ver uma prévia"),
          tags$li("Selecione as colunas desejadas (opcional)"),
          tags$li("Escolha o formato do arquivo"),
          tags$li("Clique em 'Baixar Dados'"),
          tags$li("De preferência a baixar um único ano por vez, com exceção do sistema SIA, que idealmente deve ser baixado mês a mês")
        ),
        tags$p(
          tags$strong("Obs:"), 
          "Para períodos longos, o download pode demorar alguns minutos."
        )
      )
    ),
    
    nav_panel(
      title = "Download",
      downloadTabUI("download")
    ),
    
    nav_panel(
      title = "Dicionário de Variáveis",
      dictionaryTabUI("dictionary")
    ),
    
    nav_panel(
      title = "Sobre",
      card(
        card_header("Informações sobre os Sistemas"),
        
        h4("SIM-DO (Sistema de Informações sobre Mortalidade)"),
        p("Contém informações sobre óbitos, incluindo causa mortis, local, data e dados demográficos."),
        
        h4("SINASC (Sistema de Informações sobre Nascidos Vivos)"),
        p("Registra informações sobre nascimentos, incluindo dados da mãe, da gestação e do recém-nascido."),
        
        h4("SIH-RD (Sistema de Informações Hospitalares)"),
        p("Registra todas as internações hospitalares financiadas pelo SUS."),
        
        h4("SIA-PA (Sistema de Informações Ambulatoriais)"),
        p("Contém registros de todos os atendimentos ambulatoriais realizados pelo SUS.")
      )
    )
  )
)

server <- function(input, output, session) {
  # Call module servers
  downloadServer("download")
  dictionaryServer("dictionary")
}

shinyApp(ui, server)
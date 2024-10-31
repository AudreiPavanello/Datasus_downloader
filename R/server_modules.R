# Server Modules

# Helper function to fetch and process DATASUS data
fetch_datasus_data <- function(year_start, year_end, uf, information_system, month_start = NULL, month_end = NULL) {
  # Get data
  dados <- microdatasus::fetch_datasus(
    year_start = year_start,
    year_end = year_end,
    month_start = month_start,
    month_end = month_end,
    uf = uf,
    information_system = information_system
  )
  
  dados_processados <- dados
  
  return(dados_processados)
}

downloadServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Reactive value to store the downloaded data
    data_preview <- reactiveVal(NULL)
    
    # Loading screen
    w <- Waiter$new(
      id = "preview_table",
      html = spin_dots(),
      color = transparent(.5)
    )
    
    # Preview data action
    observeEvent(input$preview, {
      w$show()
      
      # Initialize progress only when preview button is clicked
      progress <- shiny::Progress$new()
      progress$set(message = "Download em andamento", value = 0)
      
      # Initialize progress
      progress$set(message = "Baixando dados...", value = 0)
      
      tryCatch({
        # Basic parameter validation
        validate(
          need(input$ano_inicio <= input$ano_fim, "Ano inicial deve ser menor ou igual ao ano final"),
          need(input$ano_inicio >= 1996 && input$ano_fim <= 2023, "Anos devem estar entre 1996 e 2023")
        )
        
        if(input$sistema %in% c("SIH-RD", "SIA-PA")) {
          validate(
            need(
              !(input$ano_inicio == input$ano_fim && as.numeric(input$mes_inicio) > as.numeric(input$mes_fim)),
              "Mês inicial deve ser menor ou igual ao mês final quando no mesmo ano"
            )
          )
        }
        
        # Update progress
        progress$set(value = 0.3, message = "Conectando ao DATASUS...")
        
        # Fetch data using microdatasus
        if(input$sistema %in% c("SIH-RD", "SIA-PA")) {
          dados <- fetch_datasus_data(
            year_start = input$ano_inicio,
            year_end = input$ano_fim,
            month_start = as.numeric(input$mes_inicio),
            month_end = as.numeric(input$mes_fim),
            uf = input$estado,
            information_system = input$sistema
          )
        } else {
          dados <- fetch_datasus_data(
            year_start = input$ano_inicio,
            year_end = input$ano_fim,
            uf = input$estado,
            information_system = input$sistema
          )
        }
        
        # Update progress
        progress$set(value = 0.6, message = "Processando dados...")
        
        # Process data according to the information system
        dados_processados <- switch(input$sistema,
                                    "SIM-DO" = microdatasus::process_sim(dados),
                                    "SINASC" = microdatasus::process_sinasc(dados),
                                    "SIH-RD" = microdatasus::process_sih(dados),
                                    "SIA-PA" = microdatasus::process_sia(dados)
        )
        
        # Update progress
        progress$set(value = 0.8, message = "Finalizando...")
        
        # Store the processed data
        data_preview(dados_processados)
        
        # Update column selection choices
        updateSelectInput(session, "selected_columns",
                          choices = names(dados_processados),
                          selected = names(dados_processados)[1:min(5, length(names(dados_processados)))])
        
        # Complete progress
        progress$set(value = 1, message = "Concluído!")
        
      }, error = function(e) {
        shinyjs::html("error_message", paste("Erro:", e$message))
        data_preview(NULL)
        progress$set(value = 1, message = "Erro no download!")
      })
      
      w$hide()
      
      # Close progress
      progress$close()
    })
    
    # Preview table output
    output$data_loaded <- reactive({
      !is.null(data_preview())
    })
    outputOptions(output, "data_loaded", suspendWhenHidden = FALSE)
    
    output$preview_table <- renderDT({
      req(data_preview())
      data_to_show <- if (!is.null(input$selected_columns)) {
        data_preview()[, input$selected_columns, drop = FALSE]
      } else {
        data_preview()
      }
      
      datatable(
        head(data_to_show, 100),
        options = list(
          pageLength = 10,
          scrollX = TRUE
        )
      )
    })
    
    # Download handler
    output$download <- downloadHandler(
      filename = function() {
        ext <- if(input$formato == "xlsx") "xlsx" else "csv"
        paste0(
          "datasus_", tolower(input$sistema), "_",
          input$estado, "_",
          input$ano_inicio, "-", input$ano_fim,
          ".", ext
        )
      },
      content = function(file) {
        withProgress(message = 'Preparando arquivo para download...', value = 0, {
          req(data_preview())
          
          incProgress(0.3, detail = "Selecionando colunas...")
          data_to_export <- if (!is.null(input$selected_columns)) {
            data_preview()[, input$selected_columns, drop = FALSE]
          } else {
            data_preview()
          }
          
          incProgress(0.3, detail = "Gravando arquivo...")
          if(input$formato == "xlsx") {
            write.xlsx(data_to_export, file)
          } else {
            write.csv(data_to_export, file, row.names = FALSE)
          }
          
          incProgress(0.4, detail = "Finalizando...")
        })
      }
    )
  })
}

dictionaryServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$dict_table <- renderDT({
      dict_data <- switch(input$dict_sistema,
                          "SIM-DO" = dicionario_sim,
                          "SINASC" = dicionario_sinasc,
                          "SIH-RD" = dicionario_sih,
                          "SIA-PA" = dicionario_sia)
      
      datatable(
        dict_data,
        options = list(
          pageLength = 25,
          dom = 't',
          scrollY = TRUE
        )
      )
    })
  })
}
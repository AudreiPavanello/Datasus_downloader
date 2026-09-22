# Módulo de download: o coração do app.
#
# Fluxo em dois passos, que é a mudança principal em relação à versão antiga:
#
#   1. "Explorar colunas" baixa a menor fatia possível do recorte (uma UF, o
#      ano inicial e, se o sistema for mensal, só o mês inicial) apenas para
#      descobrir quais colunas existem.
#   2. "Preparar download" baixa o período inteiro passando `vars` com as
#      colunas escolhidas, de forma que o microdatasus leia só elas do DBC.
#
# A versão antiga fazia o contrário: baixava tudo, guardava na memória do
# processo do Shiny e só então deixava escolher colunas. Para SIA-PA de um
# estado grande isso significava carregar o layout inteiro, doze vezes.

mod_download_ui <- function(id) {
  ns <- shiny::NS(id)

  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 360,
      title = "Recorte dos dados",

      shiny::selectInput(
        ns("familia"),
        rotulo("Sistema", "Cada sistema do DATASUS cobre um tipo de registro."),
        choices = familias
      ),

      shiny::selectInput(
        ns("layout"),
        rotulo("Conjunto de dados", "Dentro de cada sistema há vários conjuntos, com colunas diferentes."),
        choices = NULL
      ),

      shiny::uiOutput(ns("nota_processamento")),

      bslib::input_switch(ns("todas_ufs"), "Brasil inteiro", value = FALSE),

      shiny::conditionalPanel(
        condition = sprintf("!input['%s']", ns("todas_ufs")),
        shiny::selectizeInput(
          ns("estado"),
          rotulo("Estados", "Pode escolher mais de um."),
          choices = estados,
          selected = "SP",
          multiple = TRUE
        )
      ),

      bslib::layout_columns(
        col_widths = c(6, 6),
        shiny::numericInput(ns("ano_inicio"), "Ano inicial", value = 2024, min = 1979, step = 1),
        shiny::numericInput(ns("ano_fim"), "Ano final", value = 2024, min = 1979, step = 1)
      ),

      shiny::conditionalPanel(
        condition = sprintf("output['%s']", ns("mensal")),
        bslib::layout_columns(
          col_widths = c(6, 6),
          shiny::selectInput(ns("mes_inicio"), "Mês inicial", choices = meses, selected = 1),
          shiny::selectInput(ns("mes_fim"), "Mês final", choices = meses, selected = 12)
        )
      ),

      bslib::accordion(
        open = FALSE,
        bslib::accordion_panel(
          "Opções avançadas",
          icon = bsicons::bs_icon("sliders"),
          bslib::input_switch(
            ns("processar"),
            rotulo("Aplicar rótulos", "Troca códigos por descrições legíveis. Deixa o download mais lento."),
            value = TRUE
          ),
          bslib::input_switch(
            ns("municipios"),
            rotulo("Nomes de municípios", "Acrescenta o nome do município aos códigos."),
            value = TRUE
          ),
          bslib::input_switch(
            ns("lookups"),
            rotulo("Nomes de procedimentos", "Só para SIA-PA e CNES. Baixa tabelas extras do DATASUS e demora bem mais."),
            value = FALSE
          ),
          bslib::input_switch(
            ns("parcial"),
            rotulo("Aceitar resultado parcial", "Se faltar um mês, entrega o que conseguiu em vez de falhar."),
            value = TRUE
          ),
          bslib::input_switch(
            ns("origem"),
            rotulo("Coluna de origem", "Acrescenta o nome do arquivo DBC de onde veio cada linha."),
            value = FALSE
          ),
          shiny::numericInput(
            ns("timeout"),
            rotulo("Tempo limite (s)", "Aumente para períodos longos ou conexões lentas."),
            value = 600, min = 60, max = 3600, step = 60
          )
        )
      ),

      shiny::hr(),

      # Filtrar colunas é opcional e fica ANTES do botão principal, para a
      # coluna esquerda se ler como "se quiser, refine; agora baixe". Deixar o
      # download escondido atrás da exploração obrigava quem quer o conjunto
      # inteiro a passar por uma etapa que não lhe serve.
      bslib::input_task_button(
        ns("explorar"), "Escolher colunas",
        icon = bsicons::bs_icon("funnel"),
        label_busy = "Lendo colunas...",
        type = "secondary",
        class = "w-100"
      ),
      shiny::p(
        class = "text-muted small mt-2 mb-2",
        "Opcional. Menos colunas deixa o download bem mais rápido; sem isso, vêm todas."
      ),

      shiny::conditionalPanel(
        condition = sprintf("output['%s']", ns("tem_colunas")),
        shiny::selectizeInput(
          ns("vars"),
          rotulo("Colunas", "Vazio traz todas as colunas."),
          choices = NULL, multiple = TRUE,
          options = list(placeholder = "Todas as colunas")
        ),
        shiny::div(
          class = "d-flex gap-2 mb-3",
          shiny::actionButton(ns("todas_colunas"), "Todas", class = "btn-sm btn-outline-secondary"),
          shiny::actionButton(ns("limpar_colunas"), "Limpar", class = "btn-sm btn-outline-secondary")
        )
      ),

      bslib::input_task_button(
        ns("baixar"), "Baixar tudo",
        icon = bsicons::bs_icon("cloud-arrow-down"),
        label_busy = "Baixando...",
        class = "w-100"
      ),

      shiny::conditionalPanel(
        condition = sprintf("output['%s']", ns("pronto")),
        shiny::hr(),
        shiny::radioButtons(ns("formato"), "Formato", choices = formatos_disponiveis()),
        shiny::downloadButton(ns("salvar"), "Salvar arquivo", class = "btn-primary w-100")
      )
    ),

    bslib::layout_columns(
      fill = FALSE,
      bslib::value_box("Linhas", shiny::textOutput(ns("vb_linhas")),
                       showcase = bsicons::bs_icon("list-ol"), theme = "primary"),
      bslib::value_box("Colunas", shiny::textOutput(ns("vb_colunas")),
                       showcase = bsicons::bs_icon("layout-three-columns"), theme = "secondary"),
      bslib::value_box("Período", shiny::textOutput(ns("vb_periodo")),
                       showcase = bsicons::bs_icon("calendar3"), theme = "secondary"),
      bslib::value_box("Tamanho", shiny::textOutput(ns("vb_tamanho")),
                       showcase = bsicons::bs_icon("hdd"), theme = "secondary")
    ),

    shiny::uiOutput(ns("alerta")),

    bslib::card(
      full_screen = TRUE,
      bslib::card_header("Prévia"),
      DT::DTOutput(ns("preview"))
    )
  )
}

mod_download_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {

    sonda <- nova_tarefa_sonda() |> bslib::bind_task_button("explorar")
    download <- nova_tarefa_download() |> bslib::bind_task_button("baixar")

    alerta <- shiny::reactiveVal(NULL)
    resultado_sonda <- shiny::reactiveVal(NULL)
    resultado_download <- shiny::reactiveVal(NULL)

    # Recorte que a sonda efetivamente baixou, para decidir se o passo 2 pode
    # reusar o arquivo dela em vez de ir à rede de novo.
    sonda_meta <- shiny::reactiveVal(NULL)

    # Sondas já feitas nesta sessão, por recorte. Sem isto, clicar duas vezes
    # em "Escolher colunas" baixa duas vezes.
    cache_sonda <- shiny::reactiveValues()

    # Recorte da sonda em voo. Guardado no disparo, não lido dos inputs na
    # chegada: o usuário pode mexer nos campos enquanto o download acontece, e
    # aí os inputs já não descrevem o que foi baixado.
    meta_pendente <- shiny::reactiveVal(NULL)

    # ---- Seletor família -> conjunto de dados ----

    shiny::observeEvent(input$familia, {
      shiny::updateSelectInput(session, "layout",
                               choices = layouts_da_familia(input$familia))
    })

    sistema_atual <- shiny::reactive({
      shiny::req(input$layout)
      sistema_info(input$layout)
    })

    # Trocar de conjunto invalida a exploração anterior: as colunas são outras.
    shiny::observeEvent(input$layout, {
      resultado_sonda(NULL)
      resultado_download(NULL)
      sonda_meta(NULL)
      alerta(NULL)
    }, ignoreInit = TRUE)

    output$mensal <- shiny::reactive({
      info <- sistema_info(input$layout)
      !is.null(info) && isTRUE(info$mensal)
    })
    shiny::outputOptions(output, "mensal", suspendWhenHidden = FALSE)

    output$tem_colunas <- shiny::reactive(!is.null(resultado_sonda()))
    shiny::outputOptions(output, "tem_colunas", suspendWhenHidden = FALSE)

    output$pronto <- shiny::reactive(!is.null(resultado_download()))
    shiny::outputOptions(output, "pronto", suspendWhenHidden = FALSE)

    output$nota_processamento <- shiny::renderUI({
      info <- sistema_atual()
      if (is.na(info$processador)) {
        alerta_ui("info", paste(
          "Este conjunto não tem rotulagem no microdatasus.",
          "Os dados vêm como códigos brutos do DATASUS."
        ))
      }
    })

    # ---- Parâmetros e validação ----

    parametros <- shiny::reactive({
      info <- sistema_atual()
      todas <- isTRUE(input$todas_ufs)
      mensal <- isTRUE(info$mensal)

      list(
        sistema = info$id,
        processador = if (isTRUE(input$processar)) info$processador else NA_character_,
        proc_sis = info$proc_sis,
        mensal = mensal,
        ufs = if (todas) "all" else input$estado,
        todas_ufs = todas,
        ano_inicio = input$ano_inicio,
        ano_fim = input$ano_fim,
        mes_inicio = if (mensal) as.integer(input$mes_inicio) else 0L,
        mes_fim = if (mensal) as.integer(input$mes_fim) else 0L,
        timeout = input$timeout %||% 600,
        stop_on_error = !isTRUE(input$parcial),
        track_source = isTRUE(input$origem),
        municipality_data = isTRUE(input$municipios),
        lookups = isTRUE(input$lookups)
      )
    })

    validar <- function(p) {
      erros <- c(
        validar_ufs(p$ufs, p$todas_ufs),
        validar_periodo(p$ano_inicio, p$ano_fim, p$mensal, p$mes_inicio, p$mes_fim)
      )
      if (length(erros) == 0) NULL else erros[1]
    }

    # ---- Passo 1: sonda ----

    shiny::observeEvent(input$explorar, {
      alerta(NULL)
      p <- parametros()

      erro <- validar(p)
      if (!is.null(erro)) {
        alerta(list(tipo = "danger", texto = erro))
        return()
      }

      # Para "Brasil inteiro" sondamos o Acre: o layout de colunas é o mesmo em
      # qualquer UF e é o menor arquivo, então a exploração sai barata.
      uf_sonda <- if (p$todas_ufs) "AC" else p$ufs[1]
      chave <- chave_sonda(p$sistema, uf_sonda, p$ano_inicio, p$mes_inicio)

      em_cache <- cache_sonda[[chave]]
      if (!is.null(em_cache) && file.exists(em_cache$resultado$caminho)) {
        aplicar_sonda(em_cache$resultado, em_cache$meta, do_cache = TRUE)
        return()
      }

      meta_pendente(list(sistema = p$sistema, uf = uf_sonda,
                         ano = as.integer(p$ano_inicio), mes = p$mes_inicio))

      sonda$invoke(list(
        ano = as.integer(p$ano_inicio),
        mes = p$mes_inicio,
        uf = uf_sonda,
        sistema = p$sistema,
        timeout = p$timeout
      ))
    })

    # Um único lugar que consome o resultado de uma sonda, venha ela da rede ou
    # do cache.
    aplicar_sonda <- function(r, meta, do_cache = FALSE) {
      resultado_sonda(r)
      sonda_meta(meta)

      if (length(r$colunas) == 0) {
        alerta(list(tipo = "warning", texto = paste(
          "O DATASUS não retornou dados para esse recorte.",
          "Confira o estado e o período."
        )))
        return(invisible(NULL))
      }

      shiny::updateSelectizeInput(session, "vars",
                                  choices = r$colunas,
                                  selected = character(0),
                                  server = TRUE)

      alerta(list(tipo = "success", texto = sprintf(
        "%d colunas disponíveis%s. Selecione as que interessam, ou baixe tudo.",
        length(r$colunas),
        if (do_cache) " (já lidas antes, sem novo download)" else ""
      )))
      invisible(NULL)
    }

    shiny::observeEvent(sonda$status(), {
      estado <- sonda$status()

      if (identical(estado, "error")) {
        msg <- tryCatch({ sonda$result(); "Erro desconhecido." },
                        error = function(e) conditionMessage(e))
        alerta(list(tipo = "danger", texto = traduzir_erro(msg)))
        return()
      }

      if (!identical(estado, "success")) return()

      r <- sonda$result()

      meta <- shiny::isolate(meta_pendente())
      if (is.null(meta)) return()

      chave <- chave_sonda(meta$sistema, meta$uf, meta$ano, meta$mes)
      cache_sonda[[chave]] <- list(resultado = r, meta = meta)

      aplicar_sonda(r, meta)
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$todas_colunas, {
      r <- shiny::req(resultado_sonda())
      shiny::updateSelectizeInput(session, "vars",
                                  choices = r$colunas, selected = r$colunas,
                                  server = TRUE)
    })

    shiny::observeEvent(input$limpar_colunas, {
      r <- shiny::req(resultado_sonda())
      shiny::updateSelectizeInput(session, "vars",
                                  choices = r$colunas, selected = character(0),
                                  server = TRUE)
    })

    # ---- Passo 2: download completo ----

    shiny::observeEvent(input$baixar, {
      alerta(NULL)
      p <- parametros()

      erro <- validar(p)
      if (!is.null(erro)) {
        alerta(list(tipo = "danger", texto = erro))
        return()
      }

      # Quando a sonda já baixou exatamente este recorte, o arquivo dela é
      # reusado e não há segundo download. É o caso de um sistema anual com uma
      # UF e um ano, em que a sonda sozinha já custa o download inteiro.
      s <- resultado_sonda()
      reusar <- !is.null(s) &&
        sonda_cobre_recorte(p, sonda_meta()) &&
        !is.null(s$caminho) &&
        file.exists(s$caminho)

      if (reusar) {
        alerta(list(tipo = "info", texto = paste(
          "Este recorte já foi baixado ao ler as colunas.",
          "Preparando o arquivo sem baixar de novo."
        )))
      }

      download$invoke(list(
        ano_inicio = as.integer(p$ano_inicio),
        ano_fim = as.integer(p$ano_fim),
        mes_inicio = p$mes_inicio,
        mes_fim = p$mes_fim,
        ufs = p$ufs,
        sistema = p$sistema,
        vars = input$vars %||% character(0),
        timeout = p$timeout,
        stop_on_error = p$stop_on_error,
        track_source = p$track_source,
        processador = p$processador,
        proc_sis = p$proc_sis,
        municipality_data = p$municipality_data,
        lookups = p$lookups,
        caminho_origem = if (reusar) s$caminho else ""
      ))
    })

    # O rótulo do botão principal diz o que ele vai fazer agora, para que
    # ninguém precise lembrar se selecionou colunas ou não.
    shiny::observeEvent(input$vars, {
      shiny::updateActionButton(session, "baixar",
                                label = rotulo_botao_baixar(length(input$vars)))
    }, ignoreNULL = FALSE, ignoreInit = TRUE)

    shiny::observeEvent(download$status(), {
      estado <- download$status()

      if (identical(estado, "error")) {
        msg <- tryCatch({ download$result(); "Erro desconhecido." },
                        error = function(e) conditionMessage(e))
        alerta(list(tipo = "danger", texto = traduzir_erro(msg)))
        return()
      }

      if (!identical(estado, "success")) return()

      r <- download$result()

      # O .rds da execução anterior não serve mais; o daemon vive enquanto o
      # app vive, então sem isso os temporários se acumulam.
      anterior <- resultado_download()
      if (!is.null(anterior) && file.exists(anterior$caminho)) {
        unlink(anterior$caminho)
      }
      resultado_download(r)

      if (r$nrow == 0) {
        alerta(list(tipo = "warning", texto = paste(
          "O download terminou sem nenhum registro.",
          "Confira o estado e o período."
        )))
        return()
      }

      if (!is.na(r$aviso)) {
        alerta(list(tipo = "warning", texto = paste(
          "Os dados vieram, mas sem rotulagem: as colunas escolhidas não são",
          "suficientes para o processamento do microdatasus.",
          "Escolha mais colunas ou desligue 'Aplicar rótulos'."
        )))
        return()
      }

      alerta(list(tipo = "success", texto = sprintf(
        "Pronto: %s linhas e %d colunas. Escolha o formato e salve.",
        formatar_numero(r$nrow), r$ncol
      )))
    }, ignoreInit = TRUE)

    # ---- Saídas ----

    output$alerta <- shiny::renderUI({
      a <- alerta()
      if (is.null(a)) return(NULL)
      alerta_ui(a$tipo, a$texto)
    })

    dados_exibidos <- shiny::reactive({
      r <- resultado_download()
      if (!is.null(r)) return(r$amostra)
      s <- resultado_sonda()
      if (!is.null(s)) return(s$amostra)
      NULL
    })

    output$preview <- DT::renderDT({
      d <- dados_exibidos()
      shiny::validate(shiny::need(
        !is.null(d) && nrow(d) > 0,
        "Defina o recorte e clique em 'Baixar tudo', ou em 'Escolher colunas' para filtrar antes."
      ))
      DT::datatable(
        d,
        rownames = FALSE,
        options = list(pageLength = 10, scrollX = TRUE,
                       language = list(url = "//cdn.datatables.net/plug-ins/1.13.6/i18n/pt-BR.json"))
      )
    })

    output$vb_linhas <- shiny::renderText({
      r <- resultado_download()
      if (is.null(r)) {
        s <- resultado_sonda()
        if (is.null(s)) return("--")
        return(paste0(formatar_numero(s$n), " (amostra)"))
      }
      formatar_numero(r$nrow)
    })

    output$vb_colunas <- shiny::renderText({
      r <- resultado_download()
      if (!is.null(r)) return(as.character(r$ncol))
      s <- resultado_sonda()
      if (is.null(s)) return("--")
      as.character(length(s$colunas))
    })

    output$vb_periodo <- shiny::renderText({
      p <- parametros()
      descrever_periodo(p$ano_inicio, p$ano_fim, p$mensal, p$mes_inicio, p$mes_fim)
    })

    output$vb_tamanho <- shiny::renderText({
      r <- resultado_download()
      if (is.null(r)) return("--")
      formatar_bytes(r$bytes)
    })

    # ---- Salvar ----

    # O limite do Excel é verificado antes de gravar: descobrir que o arquivo
    # não coube depois de esperar o download inteiro seria péssimo.
    shiny::observeEvent(list(input$formato, resultado_download()), {
      r <- resultado_download()
      if (is.null(r) || !identical(input$formato, "xlsx")) return()
      aviso <- checar_limite_xlsx(r$nrow)
      if (!is.null(aviso)) alerta(list(tipo = "warning", texto = aviso))
    }, ignoreInit = TRUE)

    output$salvar <- shiny::downloadHandler(
      filename = function() {
        p <- parametros()
        nome_arquivo(
          sistema = p$sistema, ufs = p$ufs,
          ano_inicio = p$ano_inicio, ano_fim = p$ano_fim,
          mes_inicio = if (p$mensal) p$mes_inicio else NULL,
          mes_fim = if (p$mensal) p$mes_fim else NULL,
          ext = input$formato, todas_ufs = p$todas_ufs
        )
      },
      content = function(file) {
        r <- resultado_download()
        shiny::validate(shiny::need(!is.null(r), "Nenhum dado preparado."))

        if (identical(input$formato, "xlsx")) {
          aviso <- checar_limite_xlsx(r$nrow)
          shiny::validate(shiny::need(is.null(aviso), aviso))
        }

        shiny::withProgress(message = "Gravando arquivo...", value = 0.5, {
          gravar_como(r$caminho, file, input$formato)
        })
      }
    )

    # Limpa o temporário da sessão ao sair.
    session$onSessionEnded(function() {
      r <- shiny::isolate(resultado_download())
      if (!is.null(r) && file.exists(r$caminho)) unlink(r$caminho)

      # Os daemons vivem enquanto o app vive, então os temporários das sondas
      # não somem sozinhos ao fim da sessão.
      for (k in shiny::isolate(names(cache_sonda))) {
        caminho <- shiny::isolate(cache_sonda[[k]])$resultado$caminho
        if (!is.null(caminho) && file.exists(caminho)) unlink(caminho)
      }
    })

    # Exposto para a aba de dicionário.
    shiny::reactive(resultado_sonda())
  })
}

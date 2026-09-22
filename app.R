# Interface para download de microdados do DATASUS.
#
# Este arquivo é só a casca: tema, navegação e chamada dos módulos. Toda a
# lógica está em R/, carregado automaticamente pelo Shiny.

tema <- bslib::bs_theme(
  version = 5,
  preset = "shiny",
  base_font = bslib::font_google("Inter"),
  heading_font = bslib::font_google("Inter"),
  "navbar-bg" = "$body-bg"
)

ui <- bslib::page_navbar(
  title = "Microdados do DATASUS",
  theme = tema,
  fillable = "Download",
  window_title = "Microdados do DATASUS",

  bslib::nav_panel("Download", mod_download_ui("dl")),
  bslib::nav_panel("Dicionário", mod_dictionary_ui("dic")),
  bslib::nav_panel("Instruções", mod_instrucoes_ui()),
  bslib::nav_panel("Sobre", mod_sobre_ui()),

  bslib::nav_spacer(),
  bslib::nav_item(
    shiny::tags$a(
      bsicons::bs_icon("github"), "Código",
      href = "https://github.com/AudreiPavanello/Datasus_downloader",
      target = "_blank", class = "nav-link"
    )
  ),
  bslib::nav_item(bslib::input_dark_mode(id = "modo"))
)

server <- function(input, output, session) {
  # A sonda do módulo de download alimenta a aba de dicionário.
  sonda <- mod_download_server("dl")
  mod_dictionary_server("dic", sonda)
}

shinyApp(ui, server)

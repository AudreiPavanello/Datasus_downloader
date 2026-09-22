# Pequenos utilitários de composição de UI.

#' Rótulo de campo com um ícone de ajuda ao lado.
#'
#' Existe para que cada campo do formulário possa se explicar sem que o usuário
#' precise abrir a aba de instruções.
rotulo <- function(texto, ajuda = NULL) {
  if (is.null(ajuda)) return(texto)
  htmltools::tagList(
    texto,
    bslib::tooltip(
      bsicons::bs_icon("info-circle", class = "ms-1 text-secondary"),
      ajuda,
      placement = "right"
    )
  )
}

#' Alerta dismissível do Bootstrap.
#'
#' Substitui o `div(style = "color: red;")` que existia antes, que nunca era
#' limpo depois de um erro e por isso mostrava mensagem obsoleta na execução
#' seguinte.
alerta_ui <- function(tipo = c("danger", "warning", "info", "success"), texto) {
  tipo <- match.arg(tipo)
  icone <- switch(tipo,
    danger  = "exclamation-octagon-fill",
    warning = "exclamation-triangle-fill",
    info    = "info-circle-fill",
    success = "check-circle-fill"
  )
  htmltools::div(
    class = paste0("alert alert-", tipo, " alert-dismissible fade show d-flex align-items-start gap-2"),
    role = "alert",
    bsicons::bs_icon(icone),
    htmltools::div(htmltools::HTML(texto)),
    htmltools::tags$button(type = "button", class = "btn-close",
                           `data-bs-dismiss` = "alert", `aria-label` = "Fechar")
  )
}

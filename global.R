# Carregado uma vez por processo R, antes de qualquer sessão.
#
# Só pacotes e configuração global. As definições do app ficam em R/, que o
# Shiny carrega automaticamente: não há `source()` explícito em lugar nenhum.
# A versão antiga duplicava os `library()` aqui e em app.R e ainda dava
# `source()` nos mesmos arquivos, de modo que cada função existia em duas ou
# três cópias.

library(shiny)
library(bslib)
library(bsicons)
library(DT)
library(mirai)

# Usados via namespace nas tarefas e na gravação: microdatasus, readr, writexl
# e, se instalado, arrow.

if (utils::packageVersion("microdatasus") < "3.0.0") {
  stop(
    "Este app requer microdatasus >= 3.0.0 (disponível no CRAN).\n",
    "Instale com: install.packages(\"microdatasus\")",
    call. = FALSE
  )
}

# Processos separados para o trabalho de rede. Sem isso, um download longo
# bloqueia o processo do Shiny e congela todas as sessões que ele atende, o que
# no shinyapps.io significa todos os usuários daquela instância.
if (mirai::daemons()$connections == 0) {
  mirai::daemons(2)
}

# Uploads não são usados, mas o limite padrão de 5 MB também afeta downloads
# grandes em algumas configurações de proxy.
options(shiny.maxRequestSize = 200 * 1024^2)

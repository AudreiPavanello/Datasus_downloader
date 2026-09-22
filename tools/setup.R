# Prepara o ambiente e grava o renv.lock.
#
# Rode uma vez na sua máquina, com internet:
#   Rscript tools/setup.R
#
# O lockfile não pode ser escrito à mão: ele guarda versão e hash de cada
# pacote, e é o que garante que o deploy no shinyapps.io instale exatamente o
# que você testou. Isso importa especialmente agora, porque o microdatasus
# acabou de mudar de major (2.x -> 3.0.0) com mudança de comportamento.

pacotes <- c(
  "shiny",        # >= 1.8.1, para ExtendedTask
  "bslib",        # >= 0.7.0, para input_task_button e input_dark_mode
  "bsicons",
  "DT",
  "mirai",        # daemons que executam o download fora do processo do Shiny
  "readr",        # write_excel_csv: UTF-8 com BOM
  "writexl",      # xlsx sem Java
  "microdatasus", # >= 3.0.0, agora no CRAN
  "renv",
  "testthat"
)

# Opcional: habilita o formato Parquet no app se estiver presente.
opcionais <- c("arrow")

faltando <- setdiff(pacotes, rownames(installed.packages()))
if (length(faltando) > 0) {
  message("Instalando: ", paste(faltando, collapse = ", "))
  install.packages(faltando)
}

versao <- utils::packageVersion("microdatasus")
if (versao < "3.0.0") {
  stop("microdatasus ", versao, " é antigo demais. Rode install.packages(\"microdatasus\").")
}
message("microdatasus ", versao, " OK")

for (p in opcionais) {
  if (!requireNamespace(p, quietly = TRUE)) {
    message("Opcional ausente (o app funciona sem): ", p)
  }
}

if (!requireNamespace("renv", quietly = TRUE)) {
  stop("renv não instalou; sem ele não há lockfile.")
}

renv::init(bare = TRUE, restart = FALSE)
renv::snapshot(packages = c(pacotes, opcionais), prompt = FALSE)
message("renv.lock gravado. Versione-o junto com o código.")

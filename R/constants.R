# Catálogo de sistemas de informação do DATASUS
#
# Uma linha por valor aceito em `information_system` do microdatasus (>= 3.0.0).
# Este data.frame dirige toda a UI (seletor família -> layout, exibição dos
# seletores de mês) e o dispatch de processamento. Não há `switch` espalhado
# pelo servidor: tudo consulta aqui.
#
# Colunas:
#   id          valor passado a fetch_datasus(information_system = )
#   familia     agrupamento exibido no primeiro seletor
#   rotulo      nome legível, exibido no segundo seletor
#   mensal      TRUE quando o sistema exige month_start / month_end
#   processador nome da função process_* do microdatasus, ou NA quando o
#               layout não tem processamento e sai como dado bruto
#   proc_sis    TRUE quando o processador exige o argumento information_system

sistemas <- local({
  linha <- function(id, familia, rotulo, mensal, processador = NA_character_,
                    proc_sis = FALSE) {
    data.frame(
      id = id, familia = familia, rotulo = rotulo, mensal = mensal,
      processador = processador, proc_sis = proc_sis,
      stringsAsFactors = FALSE
    )
  }

  rbind(
    # SIM: anual. process_sim() é documentado para o layout de mortalidade; os
    # demais layouts compartilham a estrutura, mas o resultado é conferido em
    # tempo de execução com fallback para dado bruto.
    linha("SIM-DO",    "SIM", "Declarações de óbito (geral)", FALSE, "process_sim"),
    linha("SIM-DOFET", "SIM", "Óbitos fetais",                FALSE, "process_sim"),
    linha("SIM-DOEXT", "SIM", "Óbitos por causas externas",   FALSE, "process_sim"),
    linha("SIM-DOINF", "SIM", "Óbitos infantis",              FALSE, "process_sim"),
    linha("SIM-DOMAT", "SIM", "Óbitos maternos",              FALSE, "process_sim"),

    # SINASC: anual
    linha("SINASC", "SINASC", "Declarações de nascido vivo", FALSE, "process_sinasc"),

    # SIH: mensal. Apenas RD tem processador.
    linha("SIH-RD", "SIH", "AIH reduzida",           TRUE, "process_sih", TRUE),
    linha("SIH-RJ", "SIH", "AIH rejeitada",          TRUE),
    linha("SIH-SP", "SIH", "Serviços profissionais", TRUE),
    linha("SIH-ER", "SIH", "AIH rejeitada com erro", TRUE),

    # SIA: mensal. Apenas PA tem processador.
    linha("SIA-PA",  "SIA", "Produção ambulatorial",                 TRUE, "process_sia", TRUE),
    linha("SIA-AB",  "SIA", "APAC de cirurgia bariátrica",           TRUE),
    linha("SIA-ABO", "SIA", "APAC de acompanhamento pós-bariátrica", TRUE),
    linha("SIA-ACF", "SIA", "APAC de confecção de fístula",          TRUE),
    linha("SIA-AD",  "SIA", "APAC de laudos diversos",               TRUE),
    linha("SIA-AN",  "SIA", "APAC de nefrologia",                    TRUE),
    linha("SIA-AM",  "SIA", "APAC de medicamentos",                  TRUE),
    linha("SIA-AQ",  "SIA", "APAC de quimioterapia",                 TRUE),
    linha("SIA-AR",  "SIA", "APAC de radioterapia",                  TRUE),
    linha("SIA-ATD", "SIA", "APAC de tratamento dialítico",          TRUE),
    linha("SIA-PS",  "SIA", "RAAS psicossocial",                     TRUE),
    linha("SIA-SAD", "SIA", "RAAS de atenção domiciliar",            TRUE),

    # CNES: mensal. Apenas ST e PF têm processador.
    linha("CNES-ST", "CNES", "Estabelecimentos",             TRUE, "process_cnes", TRUE),
    linha("CNES-PF", "CNES", "Profissionais",                TRUE, "process_cnes", TRUE),
    linha("CNES-LT", "CNES", "Leitos",                       TRUE),
    linha("CNES-DC", "CNES", "Dados complementares",         TRUE),
    linha("CNES-EQ", "CNES", "Equipamentos",                 TRUE),
    linha("CNES-SR", "CNES", "Serviço especializado",        TRUE),
    linha("CNES-HB", "CNES", "Habilitação",                  TRUE),
    linha("CNES-EP", "CNES", "Equipes",                      TRUE),
    linha("CNES-RC", "CNES", "Regra contratual",             TRUE),
    linha("CNES-IN", "CNES", "Incentivos",                   TRUE),
    linha("CNES-EE", "CNES", "Estabelecimento de ensino",    TRUE),
    linha("CNES-EF", "CNES", "Estabelecimento filantrópico", TRUE),
    linha("CNES-GM", "CNES", "Gestão e metas",               TRUE),

    # SINAN: anual. Leptospirose é a única sem processador.
    linha("SINAN-DENGUE",                  "SINAN", "Dengue",                  FALSE, "process_sinan_dengue"),
    linha("SINAN-CHIKUNGUNYA",             "SINAN", "Chikungunya",             FALSE, "process_sinan_chikungunya"),
    linha("SINAN-ZIKA",                    "SINAN", "Zika",                    FALSE, "process_sinan_zika"),
    linha("SINAN-MALARIA",                 "SINAN", "Malária",                 FALSE, "process_sinan_malaria"),
    linha("SINAN-CHAGAS",                  "SINAN", "Doença de Chagas",        FALSE, "process_sinan_chagas"),
    linha("SINAN-LEISHMANIOSE-VISCERAL",   "SINAN", "Leishmaniose visceral",   FALSE, "process_sinan_leishmaniose_visceral"),
    linha("SINAN-LEISHMANIOSE-TEGUMENTAR", "SINAN", "Leishmaniose tegumentar", FALSE, "process_sinan_leishmaniose_tegumentar"),
    linha("SINAN-LEPTOSPIROSE",            "SINAN", "Leptospirose",            FALSE)
  )
})

# Famílias na ordem em que aparecem no primeiro seletor.
familias <- c(
  "Mortalidade (SIM)"                = "SIM",
  "Nascidos vivos (SINASC)"          = "SINASC",
  "Internações hospitalares (SIH)"   = "SIH",
  "Produção ambulatorial (SIA)"      = "SIA",
  "Estabelecimentos de saúde (CNES)" = "CNES",
  "Agravos de notificação (SINAN)"   = "SINAN"
)

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

meses <- stats::setNames(1:12, c(
  "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
  "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
))

# Limite de linhas de uma planilha do Excel, descontada a linha de cabeçalho.
LIMITE_XLSX <- 1048575L

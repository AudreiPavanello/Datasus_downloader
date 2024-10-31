# System and location definitions
info_systems <- c(
  "Sistema de Informações sobre Mortalidade (SIM-DO)" = "SIM-DO",
  "Sistema de Informações sobre Nascidos Vivos (SINASC)" = "SINASC",
  "Sistema de Informações Hospitalares (SIH-RD)" = "SIH-RD",
  "Sistema de Informações Ambulatoriais (SIA-PA)" = "SIA-PA"
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

meses <- setNames(1:12, c(
  "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
  "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
))
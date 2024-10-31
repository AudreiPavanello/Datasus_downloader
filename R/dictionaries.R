# Data dictionaries
dicionario_sim <- data.frame(
  Variavel = c("DTOBITO", "CAUSABAS", "IDADE", "SEXO", "RACACOR", "ESC", "LOCOCOR", "CODMUNRES", "CAUSABAS_O", "COMUNINF"),
  Descricao = c(
    "Data do óbito",
    "Causa básica do óbito (CID-10)",
    "Idade do falecido",
    "Sexo do falecido",
    "Raça/cor do falecido",
    "Escolaridade",
    "Local de ocorrência do óbito",
    "Código do município de residência",
    "Causa básica original",
    "Código da unidade notificadora"
  )
)

dicionario_sinasc <- data.frame(
  Variavel = c("DTNASC", "SEXO", "PESO", "GESTACAO", "CONSULTAS", "RACACOR", "ESCMAE", "IDADEMAE", "CODMUNRES", "LOCNASC", "APGAR1"),
  Descricao = c(
    "Data de nascimento",
    "Sexo do recém-nascido",
    "Peso ao nascer (em gramas)",
    "Duração da gestação em semanas",
    "Número de consultas de pré-natal",
    "Raça/cor do recém-nascido",
    "Escolaridade da mãe",
    "Idade da mãe",
    "Código do município de residência",
    "Local do nascimento",
    "Índice de Apgar no 1º minuto"
  )
)

dicionario_sih <- data.frame(
  Variavel = c("DT_INTER", "PROC_REA", "DIAG_PRINC", "DIAS_PERM", "VAL_TOT", "CEP", "IDADE", "MUNIC_RES", "COMPLEX", "MORTE"),
  Descricao = c(
    "Data da internação",
    "Procedimento realizado",
    "Diagnóstico principal (CID-10)",
    "Dias de permanência",
    "Valor total da internação",
    "CEP do paciente",
    "Idade do paciente",
    "Município de residência",
    "Complexidade",
    "Indicador de óbito"
  )
)

dicionario_sia <- data.frame(
  Variavel = c("PA_PROC", "PA_CIDPRI", "PA_SEXO", "PA_IDADE", "PA_RACACOR", "PA_QTDAPR", "PA_VALAPR", "PA_CODUNI", "PA_CBO", "PA_GESTAO"),
  Descricao = c(
    "Código do procedimento",
    "CID principal",
    "Sexo do paciente",
    "Idade do paciente",
    "Raça/cor do paciente",
    "Quantidade aprovada",
    "Valor aprovado",
    "Código da unidade",
    "Ocupação do profissional",
    "Tipo de gestão"
  )
)
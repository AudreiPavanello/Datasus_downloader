# Descrições curadas de variáveis.
#
# Antes isto eram quatro data.frame separados, um por sistema, com ~10
# variáveis cada. Como o app agora gera o dicionário a partir do próprio dado
# baixado (ver `resumir_colunas()` em R/helpers.R), o papel deste arquivo mudou:
# ele é apenas a camada de curadoria, um lookup nome -> descrição sobreposto ao
# que foi observado.
#
# Variáveis que aparecem em mais de um sistema (CODMUNRES, SEXO, RACACOR)
# entram uma vez só, com redação neutra. Acrescentar uma variável aqui é
# acrescentar uma linha; nada mais precisa mudar.

descricoes_variaveis <- c(
  # Comuns a vários sistemas
  "SEXO"       = "Sexo",
  "RACACOR"    = "Raça/cor",
  "IDADE"      = "Idade (a unidade é indicada no próprio código)",
  "CODMUNRES"  = "Código do município de residência",
  "CODMUNOCOR" = "Código do município de ocorrência",

  # SIM
  "DTOBITO"    = "Data do óbito",
  "CAUSABAS"   = "Causa básica do óbito (CID-10)",
  "CAUSABAS_O" = "Causa básica original, antes da seleção",
  "ESC"        = "Escolaridade",
  "LOCOCOR"    = "Local de ocorrência do óbito",
  "COMUNINF"   = "Código da unidade notificadora",
  "CIRCOBITO"  = "Circunstância do óbito (causas externas)",
  "ASSISTMED"  = "Houve assistência médica",
  "NECROPSIA"  = "Houve necropsia",

  # SINASC
  "DTNASC"     = "Data de nascimento",
  "PESO"       = "Peso ao nascer, em gramas",
  "GESTACAO"   = "Duração da gestação, em semanas",
  "CONSULTAS"  = "Número de consultas de pré-natal",
  "ESCMAE"     = "Escolaridade da mãe",
  "IDADEMAE"   = "Idade da mãe",
  "LOCNASC"    = "Local do nascimento",
  "APGAR1"     = "Índice de Apgar no 1º minuto",
  "APGAR5"     = "Índice de Apgar no 5º minuto",
  "PARTO"      = "Tipo de parto",

  # SIH
  "DT_INTER"   = "Data da internação",
  "DT_SAIDA"   = "Data da saída",
  "PROC_REA"   = "Procedimento realizado",
  "DIAG_PRINC" = "Diagnóstico principal (CID-10)",
  "DIAG_SECUN" = "Diagnóstico secundário (CID-10)",
  "DIAS_PERM"  = "Dias de permanência",
  "VAL_TOT"    = "Valor total da internação",
  "CEP"        = "CEP do paciente",
  "MUNIC_RES"  = "Município de residência",
  "MUNIC_MOV"  = "Município do estabelecimento",
  "COMPLEX"    = "Complexidade do procedimento",
  "MORTE"      = "Indicador de óbito durante a internação",
  "CAR_INT"    = "Caráter da internação",

  # SIA
  "PA_PROC_ID" = "Código do procedimento ambulatorial",
  "PA_CIDPRI"  = "CID principal",
  "PA_CIDSEC"  = "CID secundário",
  "PA_SEXO"    = "Sexo do paciente",
  "PA_IDADE"   = "Idade do paciente",
  "PA_RACACOR" = "Raça/cor do paciente",
  "PA_QTDAPR"  = "Quantidade aprovada",
  "PA_QTDPRO"  = "Quantidade produzida",
  "PA_VALAPR"  = "Valor aprovado",
  "PA_VALPRO"  = "Valor produzido",
  "PA_CODUNI"  = "Código CNES da unidade",
  "PA_CBO"     = "Ocupação do profissional (CBO)",
  "PA_GESTAO"  = "Tipo de gestão",
  "PA_MUNPCN"  = "Município de residência do paciente",
  "PA_CMP"     = "Competência (AAAAMM)",

  # CNES
  "CNES"       = "Código CNES do estabelecimento",
  "FANTASIA"   = "Nome fantasia do estabelecimento",
  "TP_UNID"    = "Tipo de unidade",
  "TPGESTAO"   = "Tipo de gestão",
  "NAT_JUR"    = "Natureza jurídica",

  # SINAN
  "DT_NOTIFIC" = "Data da notificação",
  "DT_SIN_PRI" = "Data dos primeiros sintomas",
  "ID_MUNICIP" = "Município de notificação",
  "NU_IDADE_N" = "Idade codificada",
  "CS_SEXO"    = "Sexo",
  "CS_RACA"    = "Raça/cor",
  "CLASSI_FIN" = "Classificação final do caso",
  "CRITERIO"   = "Critério de confirmação",
  "EVOLUCAO"   = "Evolução do caso"
)

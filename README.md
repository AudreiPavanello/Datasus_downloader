# Microdados do DATASUS

App em R Shiny para baixar microdados do DATASUS sem escrever código. É uma
interface para o pacote [microdatasus](https://github.com/rfsaldanha/microdatasus),
de Raphael Saldanha, que faz todo o trabalho de download e tratamento.

Feito para colegas e alunos que precisam dos dados mas não programam em R.

## O que dá para baixar

43 conjuntos de dados, em seis sistemas:

| Sistema | Conjuntos | O que é |
|---|---|---|
| SIM | 5 | Mortalidade: declarações de óbito, óbitos fetais, infantis, maternos e por causas externas |
| SINASC | 1 | Nascidos vivos |
| SIH | 4 | Internações hospitalares (AIH reduzida, rejeitada, serviços profissionais) |
| SIA | 12 | Produção ambulatorial, APAC e RAAS |
| CNES | 13 | Estabelecimentos, leitos, equipamentos, profissionais, equipes |
| SINAN | 8 | Dengue, chikungunya, zika, malária, Chagas, leishmanioses, leptospirose |

## Como usar

Escolha o conjunto, o estado e o período, e clique em **Baixar tudo**. São três
passos e é o caminho normal.

Para recortes grandes existe um atalho que vale muito a pena: clicar em
**Escolher colunas** antes. O app baixa a menor fatia possível do recorte (uma
UF, o ano inicial e, se o sistema for mensal, só o mês inicial), lista as
colunas disponíveis, e o download seguinte lê **somente** as que você marcar.

Os layouts do DATASUS são largos: a produção ambulatorial (SIA-PA) passa de
uma centena de colunas, e um ano são doze arquivos. Selecionando as colunas
antes, o microdatasus lê só elas de cada arquivo em vez de carregar tudo e
descartar depois. Em recortes grandes a diferença é de ordens de grandeza, em
tempo e em memória; em recortes pequenos, tanto faz.

Quando a fatia lida para descobrir as colunas já cobre todo o recorte pedido
(uma UF, um ano, um mês), o app reaproveita esse arquivo e não baixa de novo.

Formatos de saída: CSV (UTF-8 com BOM, abre no Excel com os acentos certos),
Excel (.xlsx), RDS e, se o pacote `arrow` estiver instalado, Parquet.

## Requisitos

- R >= 4.1.0 (exigência do microdatasus 3.0.0)
- microdatasus >= 3.0.0, **agora no CRAN**

## Instalação

```r
# Instala as dependências e grava o renv.lock
Rscript tools/setup.R
```

Ou, na mão:

```r
install.packages(c(
  "shiny", "bslib", "bsicons", "DT", "mirai",
  "readr", "writexl", "microdatasus"
))
install.packages("arrow")  # opcional, habilita Parquet
```

O microdatasus saiu do GitHub para o CRAN na versão 3.0.0. Se você tem uma
instalação antiga feita com `remotes::install_github()`, atualize:

```r
install.packages("microdatasus")
packageVersion("microdatasus")  # precisa ser >= 3.0.0
```

O app checa isso na inicialização e recusa subir com versão antiga, porque o
`fetch_datasus()` mudou de assinatura.

## Rodar

```r
shiny::runApp()
```

### Processos paralelos

O download roda fora do processo do Shiny, em daemons do
[mirai](https://mirai.r-lib.org). O default é **um** daemon, porque cada um é um
processo R que segura o data.frame inteiro durante o download e a instância
gratuita do shinyapps.io tem 1 GB. Em máquina ou instância maior:

```sh
DATASUS_DAEMONS=4
```

## Testes

Cobrem as funções puras (validação, catálogo de sistemas, nomes de arquivo,
resumo de colunas, tradução de erros). Nada aqui toca a rede: o FTP do DATASUS
não é testável de forma determinística e já é responsabilidade do microdatasus.

```r
testthat::test_dir("tests/testthat")
```

## Estrutura

```
app.R                   casca: tema, navegação, chamada dos módulos
global.R                pacotes, checagem de versão, daemons do mirai
R/constants.R           catálogo dos 43 conjuntos, UFs, meses
R/dictionaries.R        descrições curadas de variáveis
R/helpers.R             funções puras (é o que os testes cobrem)
R/fetch.R               tarefas assíncronas e gravação dos formatos
R/ui_utils.R            rótulos com ajuda, alertas
R/mod_download.R        módulo principal
R/mod_dictionary.R      dicionário gerado a partir do dado explorado
R/mod_static.R          instruções e sobre
tools/setup.R           instala dependências e gera o renv.lock
```

## Notas de implementação

**Download fora do processo do Shiny.** O trabalho de rede roda em daemons do
[mirai](https://mirai.r-lib.org) via `shiny::ExtendedTask`. Sem isso, um
download longo bloqueia o processo R e congela todas as sessões que ele atende,
o que num deploy compartilhado significa todos os usuários da instância.

**O dado completo não entra na memória do app.** O daemon grava um `.rds`
temporário e devolve só o caminho, as 200 primeiras linhas e os metadados. O
arquivo é lido apenas quando você clica em salvar.

**Rotulagem é opcional e tolerante.** Selecionar poucas colunas pode remover
campos que as funções `process_*` do microdatasus esperam recodificar. Nesse
caso o app entrega os dados brutos e avisa, em vez de falhar. Só parte dos
layouts tem processamento no pacote: SIH-RD, SIA-PA, CNES-ST, CNES-PF, todo o
SIM, SINASC e sete dos oito SINAN.

## Créditos

Saldanha, R. F., Bastos, R. R., & Barcellos, C. (2019). Microdatasus: pacote
para download e pré-processamento de microdados do Departamento de Informática
do SUS (DATASUS). *Cadernos de Saúde Pública*, 35(9), e00032419.

## Licença

MIT. Ver [LICENSE](LICENSE).

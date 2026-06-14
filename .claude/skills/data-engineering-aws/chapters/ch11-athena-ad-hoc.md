# Chapter 11: Ad Hoc Queries with Amazon Athena

## Core Idea
Athena transforma o data lake em banco de dados consultável sem mover dados: SQL serverless direto no S3, sem infraestrutura para provisionar. O valor não é apenas conveniência — é democratização: analistas com SQL podem explorar o lake sem depender do data engineer para cada query. O trabalho do data engineer é otimizar o dado (Parquet, partições, tamanho de arquivo) e governar o acesso (workgroups) para que queries sejam baratas e seguras.

## Frameworks Introduced

- **Data Optimization Before Query Optimization**
  - Regra: transformar dados primeiro (Parquet + partição + file size correto) antes de otimizar SQL; impacto na performance/custo é uma ordem de magnitude maior que otimizar SQL em dados raw CSV
  - Quando usar: sempre que um novo dataset chegar no lake → pipeline de transformação é pré-requisito para query eficiente
  - Sequência: (1) Parquet + Snappy, (2) particionamento por coluna de filtro mais comum, (3) consolidar small files ≥128 MB, (4) então otimizar SQL

- **Workgroup as Governance Unit**
  - Workgroup = unidade de isolamento: engine (SQL vs Spark), result location, encryption, cost controls, query history
  - Cada time/projeto/uso ganha workgroup próprio → visibilidade de custo por alocação (cost allocation tags) + histórico isolado
  - Quando usar: qualquer organização com múltiplos times ou projetos usando Athena → criar workgroup por team ou use case; nunca deixar todos no workgroup `primary`

## Key Concepts

- **Amazon Athena**: serviço serverless baseado no Presto/Trino; permite SQL e Spark diretamente sobre S3; requer Glue Data Catalog como metastore Hive-compatível; dois modelos de cobrança: on-demand (por TB scanned) e provisioned capacity (por DPU-hora)
- **Athena Engine v3**: baseado no Trino open-source (2022); melhorias de confiabilidade e performance; suporta Hive bucketing + Spark bucketing algorithm; v2 deprecated → usar v3 em novos projetos
- **CTAS (Create Table As Select)**: Athena cria nova tabela a partir de SELECT em outra; útil para conversão one-time (CSV → Parquet) ou ad hoc; limitação: máx 100 partições por CTAS statement; para pipelines recorrentes, preferir Glue ETL job
- **Partition Projection**: configuração de padrão de partição diretamente no Glue Catalog em vez de lê-lo a cada query; elimina overhead de leitura de metadados quando número de partições é muito grande; ex.: coluna `YEARMONTH` com range `201301,NOW` e formato `yyyyMM`
- **Bucketing**: agrupa rows por hash de coluna em N buckets fixos; Athena engine v3 suporta Hive e Spark bucketing; reduz dados scanned quando query filtra pela coluna de bucket dentro de uma partição
- **approx_distinct()**: função Presto/Trino para contagem de valores únicos com desvio padrão de ~2.3%; equivalente ao HyperLogLog de Redshift; usar quando resultado aproximado é aceitável → performance significativamente superior ao COUNT(DISTINCT)
- **Query Result Reuse**: Athena engine v3; reutiliza resultado de query idêntica dentro do mesmo workgroup; default 60 min, máx 7 dias; não verifica mudanças nos dados fonte → pode retornar dados stale; ideal para dashboards com refresh frequente
- **Athena Federated Query**: executa SQL em múltiplas fontes externas via Lambda connectors; Lambda lê metadados + dados em paralelo; 30+ connectors pré-construídos (MySQL/Postgres/Redshift via JDBC, DynamoDB, Redis, CloudWatch logs/metrics, Google BigQuery, Apache Kafka/MSK, AWS CMDB); connectors customizados via SDK
- **Athena Views on External Sources**: views sobre fontes externas (federated); mascara complexidade de federated queries; controla acesso a colunas sensíveis sem duplicar dados
- **Athena for Apache Spark**: workgroup com engine Spark; notebooks Jupyter-compatíveis no console; auto-scale de executors; exploração interativa com PySpark + plots; lançado nov/2022
- **OTF Support no Athena**: Iceberg → leitura + escrita (UPDATE/INSERT/DELETE); Delta Lake → somente leitura; Hudi → somente leitura; detalhes em Ch14
- **Provisioned Capacity (DPU)**: 1 DPU = 4 CPUs + 16 GB RAM; mínimo 24 DPUs; billing $0.30/DPU-hora com mínimo de 8 horas; incrementos de 4 DPUs; usar quando há grande número de queries constantes (reduz custo vs on-demand)
- **Workgroup per-query data limit**: cancela query que exceder o limite de scan; conta cobrada pelo que foi scanned até cancelamento; útil para sandbox de usuários inexperientes
- **Workgroup data usage control**: alerta (SNS) ou ação programática (Lambda → disable workgroup) quando total scanned do workgroup ultrapassa threshold em período; não cancela queries automaticamente → mais flexível que per-query limit

## Reference Tables

### Otimizações de performance/custo — impacto decrescente

| Otimização | Ferramenta | Impacto | Quando aplicar |
|-----------|-----------|---------|---------------|
| Parquet + Snappy (vs CSV/JSON) | Glue ETL / Athena CTAS | Muito alto (~7× menos data scanned) | Todo dataset analytics |
| Particionamento por coluna de filtro | Glue ETL Spark / CTAS | Alto | Datasets com query pattern claro |
| Consolidar small files (≥128 MB) | Glue ETL | Alto | Pipelines de streaming / muitas partições pequenas |
| Bucketing por coluna de JOIN | Glue Spark / CTAS | Médio | Queries repetitivas na mesma coluna dentro de partição |
| Partition Projection | Glue Catalog config | Médio | Tabelas com centenas/milhares de partições |
| SELECT colunas específicas (vs SELECT *) | SQL | Médio | Tabelas com muitas colunas; Parquet columnar |
| approx_distinct() vs COUNT(DISTINCT) | SQL | Médio | Quando estimativa de cardinalidade é suficiente |
| Query Result Reuse | Athena setting | Médio | Dashboards com refresh frequente; queries repetitivas |

### Athena Provisioned Capacity — referência de DPUs

| Queries concorrentes | DPUs recomendados | Custo/hora (USD) |
|---------------------|------------------|-----------------|
| 10 | 40 | $12.00 |
| 20 | 96 | $28.80 |
| 30+ | 240 | $72.00 |
| Mínimo obrigatório | 24 | $7.20 |

> Billing mínimo: 8 horas por reserva. On-demand: $5/TB scanned. Calcular break-even por workload.

### Workgroup — configurações de governança

| Configuração | Objetivo | Quando usar |
|-------------|---------|-------------|
| Query Result Location | Controlar onde resultados vão no S3 | Sempre; cada workgroup → path separado |
| Encrypt Query Results (SSE_S3 / KMS) | Proteger dados de resultado | Sempre em produção |
| Override client-side settings | Impedir usuário de alterar path/encryption | Sempre que compliance importa |
| Per-query data limit | Hard cancel de queries excessivas | Sandbox de usuários inexperientes |
| Workgroup data usage control | Alertar / agir quando total do workgroup ultrapassa threshold | Times com orçamento definido |
| Cost Allocation Tags | Alocar custo por team/projeto em Cost Reports | Organização com múltiplos times |
| Publish metrics to CloudWatch | Monitoramento de queries, runtime, data scanned | Produção; visibilidade operacional |

### Athena Federated Query — connectors pré-construídos

| Connector | Fontes suportadas |
|-----------|------------------|
| JDBC | MySQL, Postgres, Redshift, MariaDB, SQL Server |
| DynamoDB | Amazon DynamoDB |
| Redis | Redis / ElastiCache |
| CloudWatch | Logs, Metrics |
| AWS CMDB | EC2, RDS, EMR, S3 resources |
| Google BigQuery | BigQuery cross-cloud |
| Apache Kafka | Kafka topics, Amazon MSK |
| Customizado | Qualquer sistema com conectividade Lambda → target |

## Worked Example

**Hands-on Ch11 — Workgroup + Queries no data lake**

**Objetivo**: criar workgroup com governança e custo controlado, executar queries no `streaming_films`.

**Workgroup `datalake-user-sandbox`**:
```
Query result location:  s3://aws-athena-query-results-dataengbook-<initials>/datalake-user-sandbox/
Encryption:             SSE_S3
Override client-side:   Enabled
Per-query data limit:   10 GB  → cancela query se scan > 10 GB (~$0.05 máximo por query)
```

**Query 1 — top categorias de streaming** (curatedzonedb.streaming_films):
```sql
SELECT category_name, count(category_name) streams
FROM streaming_films
GROUP BY category_name
ORDER BY streams DESC
```
→ Retorna Sports como categoria mais popular (dados aleatórios do Kinesis Data Generator do Ch06).

**Query 2 — top estados**:
```sql
SELECT state, count(state) count
FROM streaming_films
GROUP BY state
ORDER BY count DESC
```
→ Alaska no topo (dados aleatórios).

**CTAS — converter tabela CSV para Parquet** (exemplo de otimização one-time):
```sql
CREATE TABLE customers_parquet
WITH (
  format = 'Parquet',
  parquet_compression = 'SNAPPY'
)
AS SELECT * FROM customers_csv;
```
→ Nova tabela `customers_parquet` com mesmos dados, arquivos Parquet + Snappy no S3.

**Resultado da governança**:
- Saved queries visíveis apenas no workgroup → isolamento de histórico por time
- Recent queries: últimas 45 dias; download de resultados como CSV direto do console
- Reuse query results: executar mesma query ≥2× → segunda execução retorna resultado cacheado (0 dados scanned, 0 custo adicional)

## Key Takeaways

1. Parquet + partição são pré-requisito: Athena cobra por dados scanned; dado não otimizado = query cara + lenta; transformação de CSV → Parquet é o maior lever de custo disponível
2. CTAS é o atalho de Athena para conversão one-time: sem precisar de Glue job para transformações pontuais; limitação de 100 partições por statement
3. Federated Query elimina ETL para fontes acessadas raramente: se dataset é consultado com baixa frequência por poucos times, Athena lê direto da fonte (Aurora, DynamoDB, BigQuery) sem carregar no lake
4. Workgroups não são opcionais em produção: sem workgroup separado, múltiplos times compartilham histórico de queries, resultado location e limites de custo → criar workgroup por time ou projeto é governança básica
5. Per-query limit para sandbox, workgroup usage control para orçamento: limites distintos para casos distintos; per-query cancela individual; workgroup usage alerta e age programaticamente no agregado
6. approx_distinct() e query reuse são os dois "freebies" de performance: drop-in replacement para COUNT(DISTINCT) com ~2.3% de desvio; reuse elimina custo de queries idênticas dentro de 60 min (ou até 7 dias)
7. Athena engine v3 é obrigatório para novos projetos: v2 será deprecated; v3 traz suporte a bucketing Spark + melhorias de performance; configurar em todo workgroup novo

## Connects To

- **Ch07**: Parquet + particionamento gerados pelo Glue ETL são o input ideal para Athena; CTAS como alternativa para conversão ad hoc
- **Ch08**: Athena é a ferramenta primária para data analysts (SQL ad hoc); DataBrew recipes chamáveis a partir de Glue Studio mas Athena para exploração livre
- **Ch09**: Redshift Spectrum compartilha o mesmo Glue Data Catalog → mesma tabela externa queryável por Athena e Spectrum em paralelo; escolher por latência e concorrência
- **Ch10**: Athena SDK call disponível como Task state no Step Functions para queries agendadas em pipelines
- **Ch12**: QuickSight pode usar Athena como datasource direto para dashboards (sem carregar em SPICE)
- **Ch14**: OTFs (Iceberg, Hudi, Delta Lake) têm suporte diferenciado no Athena; Iceberg com read+write completo; detalhes em Ch14

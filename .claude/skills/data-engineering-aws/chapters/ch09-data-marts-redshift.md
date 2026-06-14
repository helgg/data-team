# Chapter 9: A Deeper Dive into Data Marts and Amazon Redshift

## Core Idea
Data lake é fonte única da verdade, mas nem todo dado deve ser consultado de lá. Dados "quentes" — acessados múltiplas vezes por dia, com requisito de baixa latência — precisam de um data mart de alta performance. Amazon Redshift é o motor analítico OLAP AWS-native: arquitetura MPP com distribuição de dados por slices, Zone Maps para skip de blocos, e features avançadas (Spectrum, data sharing, ML) que estendem o lake sem duplicação.

## Frameworks Introduced

- **Data Temperature Tiering**
  - **Cold**: raramente acessado; compliance/histórico; S3 Glacier (Flexible ou Deep Archive); não queryável diretamente com Athena em Glacier Flexible/Deep Archive
  - **Warm**: acessado regularmente mas sem requisito de baixíssima latência; data lake zones (landing/clean/curated); S3 Standard ou Infrequent Access; queryável com Athena
  - **Hot**: acessado múltiplas vezes/dia; dashboards BI, KPIs executivos; precisa de engine de alta performance (Redshift RMS ou QuickSight SPICE)
  - Quando usar: classificar cada dataset por temperatura antes de decidir storage engine; não colocar cold data em Redshift (caro demais)

- **Redshift Distribution Style Selection**
  - **AUTO** (padrão recomendado): Redshift monitora queries e otimiza automaticamente; começa como ALL (tabelas pequenas) ou EVEN (grandes); migra para KEY quando análise detectar padrão de join
  - **ALL**: cópia da tabela em todos os slices; ideal para dimension tables pequenas (2–3M rows) → elimina shuffle em joins com fact tables
  - **EVEN**: round-robin; distribui rows uniformemente; ideal para fact tables grandes sem coluna clara de join
  - **KEY**: hash de coluna determina slice; rows com mesmo valor ficam no mesmo slice; otimiza JOIN e GROUP BY na mesma coluna; evitar em colunas usadas em WHERE (bottleneck) e em colunas de baixa cardinalidade (hot partition)
  - Quando usar: deixar AUTO inicialmente; revisar manualmente só se performance insuficiente após período de uso real

## Key Concepts

- **Redshift MPP (Massively Parallel Processing)**: leader node + N compute nodes; cada compute node dividido em 2/4/16 slices; cada slice processa subset dos dados em paralelo; query speed = slowest slice (evitar data skew)
- **Redshift Zone Maps**: metadata in-memory no leader node sobre min/max de cada bloco de 1 MB por coluna; permite skip de blocos irrelevantes antes de lê-los do disco; efetividade depende de data estar sorted → sort keys
- **Sort Keys**: compound (prioridade ordenada de colunas — default e recomendado para maioria) vs interleaved (peso igual entre colunas); usar em colunas de range filters ou aggregations frequentes; prejudica performance de ingest
- **Redshift Managed Storage (RMS)**: RA3 nodes desacoplam compute de storage; SSD local = hot cache; S3 managed storage = overflow; Redshift move dados automaticamente entre tiers baseado em temperatura de acesso
- **Redshift Serverless vs Provisioned**: Serverless → paga por RPU consumido, auto-scale, sem maintenance window, pausa automática; custo imprevisível → usar para workloads imprevisíveis ou dev/test; Provisioned → custo previsível (pode usar Reserved Instances 1/3 anos), melhor para workloads constantes
- **Redshift Spectrum**: external tables no Glue Data Catalog; Redshift lê dados diretamente do S3 via MPP sem carregar no cluster; suporta OTFs (Delta Lake, Hudi; Iceberg em preview no momento do livro); custo = provisioned: por TB scanned; serverless: por RPU consumido
- **Materialized Views**: pré-computa joins + aggregations caras; BI tool consulta view (igual a tabela); refresh manual (`REFRESH MATERIALIZED VIEW`) ou automático; Redshift prioriza outras queries no auto-refresh → pode atrasar
- **Temporary Tables (staging)**: session-specific (apagadas no fim da sessão); não replicadas; não disparam backup incremental; padrão para CDC: load snapshot em temp table → `MERGE` para upsert na tabela target
- **COPY command**: ingestão bulk em Redshift; fontes: S3, DynamoDB, EMR, SSH; formatos: CSV, Parquet, Avro, JSON, ORC; performance máxima = número de arquivos = número de slices; 1 transação para todos os arquivos (falha em 1 arquivo → rollback total); arquivo ideal: 1 MB–1 GB comprimido
- **UNLOAD command**: exporta Redshift → S3; paralelo via múltiplos slices; MAX 6.2 GB por arquivo (recomendar MAXFILESIZE 1 GB); suporta Parquet (recomendado → até 2× mais rápido); `PARTITION BY` gera Hive partitioning no S3; `CLEANPATH` apaga só partições escritas (não o prefix todo)
- **Redshift Data Sharing**: cluster RA3 compartilha dados "live" (read-only) com outro cluster RA3 (mesma ou diferente conta, cross-region); uso principal: separar cluster ELT (writes) de cluster consumers (reads); billing por cluster → fácil alocar custo por time
- **Redshift ML**: `CREATE MODEL` em SQL → exporta dataset para S3 → SageMaker AutoPilot treina modelo → function disponível em SQL; ex: `SELECT predict_churn(zip, tenure, spend, calls) FROM customers`
- **Dynamic Data Masking (DDM)**: policy de masking aplicada em query time (sem transformar dado armazenado); suporta redact total, parcial (últimos 4 dígitos), hash; granularidade por role de usuário
- **Zero-ETL Aurora→Redshift**: dados de Aurora MySQL aparecem em Redshift em segundos; elimina pipeline DMS para OLAP; em preview no momento do livro (Aurora MySQL 8.0 apenas)
- **HLLSKETCH type**: armazena resultado do algoritmo HyperLogLog para estimativa eficiente de cardinalidade em grandes datasets (erro ~0.01–0.6%); ex: unique visitors por dia em site com centenas de milhões de acessos
- **SUPER type**: semi-structured data (JSON, arrays) até 1 MB por campo; dynamic typing na query; não requer schema prévio; performance superior a unnest de JSON com centenas de atributos
- **Anti-patterns de data warehouse**: (1) OLTP em Redshift (upsert frequente, FK enforcement — não suportado); (2) usar como data lake (armazenar raw data cara demais vs S3); (3) ELT pesado em Redshift quando transformação poderia ocorrer no lake; (4) dados não estruturados (imagens, áudio — não suportados)

## Reference Tables

### S3 Storage Classes — quando usar

| Classe | Acesso | Custo | Query com Athena | Uso típico |
|--------|--------|-------|-----------------|------------|
| S3 Standard | Imediato (ms) | Alto storage, sem retrieval | Sim | Landing/clean/curated zones (últimos 1–3 meses) |
| S3 Standard-IA | Imediato (ms) | Menor storage + retrieval fee | Sim | Dados 3–24 meses (acesso mensal) |
| S3 One Zone-IA | Imediato (ms) | Menor que Standard-IA, 1 AZ | Sim | Dados recriáveis facilmente |
| Glacier Instant Retrieval | Imediato (ms) | Baixo storage, retrieval fee | Sim | Acesso ~1×/trimestre |
| Glacier Flexible Retrieval | Minutos–horas | Muito baixo | **Não** (precisa restaurar) | Acesso ~1–2×/ano |
| Glacier Deep Archive | 9–12 horas | Mais baixo | **Não** (precisa restaurar) | Compliance de longo prazo |
| S3 Intelligent Tiering | Imediato (ms) | Auto-otimizado | Sim (exceto Archive Access) | Padrão recomendado para data lake |

> S3 Lifecycle rules: automação por dias desde criação. Intelligent Tiering: automação por dias desde último acesso. Preferir Intelligent Tiering para data lake.

### Redshift Node Types — quando usar

| Família | Storage | Compute/storage | Quando usar |
|---------|---------|-----------------|-------------|
| RA3 | Managed (SSD local + S3) | Desacoplados | DW > 1 TB; acesso a features avançadas (data sharing); escalabilidade independente |
| DC2 | SSD local fixo | Acoplados | DW < 1 TB; workloads compute-intensivos |
| DS2 (legacy) | HDD grande | Acoplados | Não recomendado para novos clusters |

### Data Ingestion — COPY vs alternativas

| Método | Performance | Quando usar |
|--------|-------------|-------------|
| `COPY` de S3 (Parquet) | Máxima — paralelo por slices | Padrão para carga bulk |
| `COPY` com split de arquivos | Alta — 1 arquivo por slice | Arquivos grandes → split em N arquivos = N slices |
| Spark-Redshift JDBC (EMR 6.9+, Glue 4.0+) | Alta — escreve S3 temp + COPY interno | Spark DataFrame → Redshift sem gerenciar COPY manualmente |
| `INSERT` multi-row | Baixa | Evitar; último recurso para poucos registros |
| `INSERT` single-row | Muito baixa | Nunca usar em produção |

### Redshift Table Types

| Tipo | Persistência | Quando usar |
|------|-------------|-------------|
| Local table (RMS) | Permanente | Hot data — máxima performance de query |
| External table (Spectrum) | Ponteiro → Glue Catalog / S3 | Dados warm/históricos no lake; 80% queries em 12 meses, 20% em 5 anos |
| Temporary table | Sessão | Staging para CDC merge; operações não-replicadas |
| Materialized view | Permanente (cache) | Pré-computar joins/aggregations caros para BI |

## Worked Example

**Hands-on Ch09 — Redshift Serverless + Spectrum: query de data lake sem carregar dados**

**Objetivo**: criar cluster Redshift Serverless, configurar Spectrum para ler CSV do S3 como external table, e consultar via Redshift e Athena.

**IAM Role para Redshift Spectrum** (4 policies):
```
AmazonS3FullAccess
AWSGlueConsoleFullAccess
AmazonAthenaFullAccess
AmazonRedshiftAllCommandsFullAccess
```
Role name: `AmazonRedshiftSpectrumRole`
> Em produção: substituir por policies com escopo limitado aos buckets do projeto.

**Criar external schema (Redshift Query Editor v2)**:
```sql
CREATE EXTERNAL SCHEMA spectrum_schema
FROM DATA CATALOG
DATABASE 'users'
IAM_ROLE 'arn:aws:iam::1234567890:role/AmazonRedshiftSpectrumRole'
CREATE EXTERNAL DATABASE IF NOT EXISTS;
```
→ Cria novo database `users` no Glue Data Catalog + schema `spectrum_schema` no Redshift database `dev`.

**Criar external table apontando para CSV no S3**:
```sql
CREATE EXTERNAL TABLE spectrum_schema.user_details (
  id         INTEGER,
  first_name VARCHAR(40),
  last_name  VARCHAR(40),
  email      VARCHAR(60),
  gender     VARCHAR(15),
  address_1  VARCHAR(80),
  address_2  VARCHAR(80),
  city       VARCHAR(40),
  state      VARCHAR(25),
  zip        VARCHAR(5),
  phone      VARCHAR(12)
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://dataeng-landing-zone-<initials>/users/'
TABLE PROPERTIES ('skip.header.line.count'='1');
```

**Query de validação** (mesma tabela acessível via Redshift e via Athena):
```sql
-- Redshift (Spectrum)
SELECT * FROM spectrum_schema.user_details LIMIT 10;

-- Athena (mesma tabela no Glue Catalog → database 'users', table 'user_details')
SELECT * FROM "users"."user_details" LIMIT 10;
```

**Fluxo de dados resultante**:
```
S3 (CSV) → Glue Data Catalog (users.user_details)
                ├── Athena: query direta no lake
                └── Redshift Spectrum: query via spectrum_schema.user_details (MPP)
```

**Exemplo de COPY + UNLOAD para hot data**:
```sql
-- Ingestão: curated zone → Redshift local table (bulk load)
COPY sales_fact
FROM 's3://dataeng-curated-zone-<initials>/sales/'
IAM_ROLE 'arn:aws:iam::1234567890:role/AmazonRedshiftSpectrumRole'
FORMAT AS PARQUET;

-- Exportação: resultado processado → data lake (Hive partitioning, Parquet)
UNLOAD ('SELECT * FROM sales_summary ORDER BY year, month')
TO 's3://dataeng-curated-zone-<initials>/sales-summary/'
IAM_ROLE 'arn:aws:iam::1234567890:role/AmazonRedshiftSpectrumRole'
FORMAT PARQUET
PARTITION BY (year, month)
MAXFILESIZE 1 GB
CLEANPATH;
```

## Key Takeaways

1. Temperatura define engine: cold → Glacier; warm → S3 + Athena; hot → Redshift RMS ou QuickSight SPICE; nunca colocar cold data em Redshift
2. Deixar distribuição e sort key em AUTO para começar — Redshift usa ML para otimizar automaticamente após N queries; ajuste manual só quando necessário
3. COPY é o único método de ingestão recomendado em bulk; split de arquivo em N = número de slices maximiza paralelismo; 1 transação = 1 rollback se qualquer arquivo falhar
4. Redshift Spectrum evita duplicação de dados: tabela externa aponta para S3, Redshift usa MPP para ler — dados warm/históricos ficam no lake, só hot data é carregado localmente
5. Materialized views são o cache do Redshift para BI: pré-computam joins caros; BI tool consulta view como se fosse tabela; refresh noturno após carga diária
6. S3 Intelligent Tiering recomendado como padrão para data lake: move automaticamente por padrão de acesso sem overhead de gestão, sem custo de retrieval
7. Anti-pattern crítico: usar data warehouse como lake (armazenar raw data em Redshift = custo alto, rigidez de schema, sem suporte a dados não estruturados)

## Connects To

- **Ch02**: Arquitetura Redshift (leader + compute nodes, dimensional modeling) introduzida aqui em profundidade
- **Ch05**: Data mart Redshift identificado no whiteboard do Projeto Bright Light para hot data de BI
- **Ch07**: Dados curated zone (Parquet, particionados) são input ideal para COPY command
- **Ch08**: QuickSight conecta ao Redshift como fonte de alta performance para business users
- **Ch11**: Athena e Redshift Spectrum compartilham o mesmo Glue Data Catalog — query da mesma tabela externa por dois engines diferentes
- **Ch12**: QuickSight SPICE como alternativa ao Redshift para caching em memória de dashboards
- **Ch14**: Redshift Spectrum suporta leitura de OTFs (Delta Lake, Hudi, Iceberg) — integração com transactional data lake
- **Ch15**: Data sharing do Redshift como mecanismo de distribuição de dados em arquitetura Data Mesh

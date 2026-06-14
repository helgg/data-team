# Chapter 7: Transforming Data to Optimize for Analytics

## Core Idea
Transformação é onde dados brutos viram valor de negócio: combine fontes diferentes com a "receita" certa para o contexto certo (bolo vs café da manhã). Há dois eixos de decisão — qual engine usar e qual tipo de transformação aplicar — e eles são independentes.

## Frameworks Introduced

- **Transformation Engine Selection Framework**
  - **Apache Spark**: in-memory, distribuído em cluster; batch e streaming (Spark Streaming); suporta SQL (Spark SQL), ML (Spark ML), grafos (GraphX); melhor desempenho para a maioria dos casos
  - **Hadoop MapReduce**: disk-based (vs in-memory do Spark); útil para datasets massivos que não cabem economicamente em memória; legado mas ainda amplamente em produção
  - **SQL (ELT/ETL)**: acessível (skill widespread); ELT quando target é warehouse (Redshift/Snowflake — carrega raw, transforma dentro); ETL quando Spark processa + carrega no destino
  - **GUI-based tools**: drag-and-drop; Glue DataBrew (250+ transformações visuais, sem código) e Glue Studio (visual Spark, gera código editável); Informatica, Matillion, Fivetran externamente
  - Quando usar: equipe sem Spark → DataBrew/SQL; alta throughput/complexidade → Spark; migração Hadoop → EMR

- **Two-Phase Transformation Model**
  - **Fase 1 — Preparação genérica**: PII protection, CSV→Parquet, particionamento, data cleansing; não requer entender o uso final do dado
  - **Fase 2 — Transformações de negócio**: denormalização, enriquecimento, pré-agregação, extração de metadata de dados não estruturados; requer entender consumers e use cases
  - Quando usar: estruturar pipeline em duas fases distintas; fase 1 roda para todos os datasets ingeridos; fase 2 é específica por use case

- **CDC Handling Decision Framework**
  - **Abordagem tradicional — upsert Spark**: DataFrame existente + DataFrame CDC → merge custom logic → overwrite ou nova partição snapshot; complexo, não genérico, pode bloquear consumers durante write
  - **Abordagem tradicional — Athena views**: view combina tabela existente + CDC table; consumer vê dado atual sem esperar job diário; degrada performance conforme CDC cresce; manter view + job diário = complexidade dupla
  - **Abordagem moderna — OTFs (Open Table Formats)**: ACID semantics no data lake; upsert/delete nativos; schema evolution; time travel; escolher entre Iceberg, Hudi, Delta Lake
  - Quando usar: novo projeto → preferir OTF (Ch14); legado → avaliar custo de migração vs manutenção de upsert custom

## Key Concepts

- **Apache Parquet (column-based)**: dados organizados por coluna, não por linha; query que seleciona 3 colunas de 100 lê apenas 3% dos dados; metadata por chunk (min/max) permite skip de chunks irrelevantes; COUNT(*) retorna 0 KB scanned; compressão Snappy: 1 TB CSV → ~130 GB Parquet
- **Hive Partitioning**: organiza arquivos S3 em prefixos baseados em coluna(s); `year=2023/file1.parquet`; query com `WHERE year=2023` lê apenas 1 prefixo; anti-pattern: particionar por coluna que não é usada em queries → overhead sem benefício
- **Small files problem**: Parquet ótimo = 128 MB – 1 GB por arquivo; muitas partições pequenas = overhead de open/read metadata/close por arquivo; preferir menos partições com arquivos maiores
- **Data Denormalization (OLAP)**: OLTP normaliza (sem repetição, foreign keys); OLAP desnormaliza (join prévio, tabela wide) para evitar joins em query time; custo: redundância de storage (irrelevante com S3)
- **Data Enrichment**: join de dados próprios com dados de terceiros via AWS Data Exchange (1.000+ datasets, delivery direto para S3); exemplos: credit scores, dados meteorológicos
- **Pre-aggregation**: calcular métricas complexas (vendas por loja/categoria/estado) em job agendado; consumers consultam resultado agregado, não raw data → latência zero no dashboard
- **Metadata extraction (unstructured)**: Amazon Rekognition → identificar objetos/cômodos em imagens; Amazon Transcribe → transcrição de áudio; Amazon Comprehend → sentiment analysis; output vira dataset estruturado para analytics
- **ACID in OTFs**: Atomicity (tudo ou nada), Consistency (sem estado inválido em falha), Isolation (transações simultâneas não se afetam), Durability (committed = permanente)
- **Apache Iceberg**: criado na Netflix; top-level Apache 2020; suporta schema evolution, time travel, atomic changes, multiple simultaneous writers; suporte nativo no AWS Glue
- **Apache Hudi**: criado no Uber; top-level Apache 2020; foco em upsert eficiente e query de dados recentes; suporte no EMR e Glue
- **Delta Lake**: criado pela Databricks (fundadores do Spark); open-source + versão comercial; ACID para insert/update/delete; time travel; popular em grandes enterprises
- **Glue Job Bookmark (disable em testes)**: rastreia arquivos processados para não reprocessar; desabilitar em desenvolvimento onde re-runs são necessários
- **Auto-scaling Glue workers**: habilitar em produção — Glue ajusta número de workers dinamicamente, minimiza workers ociosos e custo
- **ELT vs ETL**: ELT = Extract→Load→Transform (raw no warehouse, transform com SQL interno); ETL = Extract→Transform→Load (transform antes de carregar, ex.: Spark → S3 clean zone)

## Reference Tables

### Engines de transformação — quando usar

| Engine | AWS Services | Quando usar | Limitação |
|--------|-------------|-------------|-----------|
| Apache Spark | Glue ETL, EMR, EMR Serverless, EKS/ECS | Datasets grandes; streaming; ML; GraphX | Skill requirement; custo maior vs SQL para jobs simples |
| Hadoop MapReduce | EMR | Datasets enormes que não cabem em memória | Disk-based = mais lento; Spark preferível na maioria dos casos |
| SQL | Athena, Redshift, Glue Studio (SQL nodes) | Skill widespread; ELT em warehouse | Menos versátil para transformações complexas/customizadas |
| GUI (visual) | Glue DataBrew, Glue Studio Visual | Sem Spark skills; 250+ transforms prontos; PII detection | Menor flexibilidade; pode não cobrir casos complexos |
| Commercial | Informatica, Matillion, Fivetran, Stitch | Ecossistema existente; integração SaaS | Custo de licença; vendor lock-in |

### Transformações de preparação (Fase 1)

| Transformação | Ferramenta AWS | Quando é crítica |
|--------------|----------------|-----------------|
| PII protection | Glue DataBrew (redact/hash/encrypt/swap), Glue Studio (redact/hash) | Sempre que dataset contém PII — primeira transformação |
| CSV → Parquet | Lambda (leve), Glue ETL (grande volume) | Todo dataset ingerido para analytics |
| Particionamento | Glue ETL (Spark write com partitionBy) | Datasets com query pattern claro por coluna |
| Data cleansing | Glue DataBrew (250+), Glue ETL | IoT, formulários web, dados manuais, streaming |

### Transformações de negócio (Fase 2)

| Transformação | Quando usar | Benefício |
|--------------|-------------|-----------|
| Denormalização | Joins frequentes em OLAP queries | Elimina joins em query time |
| Enriquecimento | Dados próprios + terceiros (Data Exchange) | Novos insights impossíveis com dados isolados |
| Pré-agregação | Métricas recorrentes com cálculo pesado | Dashboard latência zero; reduz carga de compute |
| Metadata de não-estruturado | Imagens, áudio, vídeo | Habilita analytics em fontes antes inacessíveis |

### CDC: abordagens tradicionais vs modernas

| Aspecto | Upsert Spark | Athena View | OTF (Iceberg/Hudi/Delta) |
|---------|-------------|-------------|--------------------------|
| Complexidade | Alta (custom logic por dataset) | Média | Baixa (nativo) |
| Latência para consumer | Alta (aguarda job diário) | Baixa (view imediata) | Baixa (commit atômico) |
| Performance ao longo do tempo | Degradação com volume | Degradação com CDC crescente | Estável |
| ACID | Não | Não | Sim |
| Time travel | Sim (snapshots manuais) | Não | Sim (nativo) |
| Recomendação | Legado sem OTF | Transição temporária | Novo projeto |

## Worked Example

**Hands-on Ch07 — Glue Studio: Denormalização + Enriquecimento (Sakila + Streaming)**

**Objetivo**: criar tabela `streaming_films` na curated zone que une streaming events com metadata de filmes (incluindo category), eliminando joins em query time para análise de popularidade por categoria.

**IAM policy para Glue job** (duas cláusulas):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": [
        "arn:aws:s3:::dataeng-landing-zone-<initials>/*",
        "arn:aws:s3:::dataeng-clean-zone-<initials>/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": "arn:aws:s3:::dataeng-curated-zone-<initials>/*"
    }
  ]
}
```
Role: `DataEngGlueCWS3CuratedZoneRole` = policy acima + `AWSGlueServiceRole` (managed).

**Job 1 — Film Category Denormalization** (3 tabelas sakila → 1 tabela curated):

```
S3 - film_category ─────┐
                         ├─► Join (Left, film_id) ─► Change Schema ─► Join (Left, category_id) ─► Change Schema ─► S3 curated
S3 - film ──────────────┘                                              ▲
                                                                       │
S3 - category ─────────────────────────────────────────────────────────┘
```

Configuração do target S3:
- Format: `Parquet` / Compression: `Snappy`
- S3 path: `dataeng-curated-zone-<initials>/filmdb/film_category/`
- Glue database: `curatedzonedb`, table: `film_category`
- Data Catalog update: "Create table; on subsequent runs, update schema and add new partitions"

Configuração do job:
- Workers: 2 (mínimo — dataset pequeno)
- Job bookmark: **Disable** (testes precisam de re-runs)
- Retries: 0
- Auto-scaling: Enable (boas práticas em produção)

**Job 2 — Streaming Data Film Enrichment**:

```
S3 - film_category (curated) ─────────────────┐
                                               ├─► Join (Left, film_id) ─► S3 curated/streaming/streaming-films/
S3 - Streaming ─► Change Schema ──────────────┘
                  (rename film_id → film_id_streaming)
```

Output: tabela `streaming_films` em `curatedzonedb` — joins pré-calculados, consulta direta por categoria, estado, plataforma.

**Resultado**: query `SELECT category_name, COUNT(*) FROM streaming_films GROUP BY category_name` roda sem joins, direto no Athena.

## Key Takeaways

1. Separar pipeline em duas fases: preparação genérica (Fase 1, independente de use case) e transformações de negócio (Fase 2, específicas); facilita reúso e manutenção
2. Parquet + Snappy é o padrão para data lakes analytics: compressão ~7x vs CSV, query por coluna, metadata de min/max para predicate pushdown
3. Particionar pelo campo mais usado em queries; múltiplas partições granulares criam "small files problem" — 128 MB–1 GB por arquivo é o target
4. Denormalização no data lake é oposta à normalização OLTP: pre-join tables para eliminar overhead de join em query time
5. Pre-aggregação transforma dashboards de "cálculo pesado em cada refresh" para "leitura de resultado pré-computado" — entender queries frequentes do consumer é pré-requisito
6. CDC com OTFs (Iceberg, Hudi, Delta Lake) é superior às abordagens tradicionais para projetos novos; abordagens custom (upsert Spark, Athena views) são complexas e degradam com o tempo
7. Glue Studio visual gera código Spark editável — bom ponto de partida para quem está aprendendo Spark ou precisa acelerar desenvolvimento

## Connects To

- **Ch03**: Glue ETL, EMR, Glue DataBrew introduzidos como toolkit — aqui aplicados com critérios de seleção
- **Ch05**: Transformações whiteboarded no Projeto Bright Light (Fase 1 e 2) concretizadas aqui
- **Ch06**: Dados ingeridos (Sakila via DMS + streaming via Kinesis) são os inputs dos jobs deste capítulo
- **Ch08**: Dataset `streaming_films` curated é o que os data consumers (Athena, QuickSight, Redshift) vão consumir
- **Ch09**: Subset do curated zone carregado no Redshift para BI de baixa latência
- **Ch14**: OTFs (Iceberg, Hudi, Delta Lake) detalhados — alternativa ACID ao padrão file-based para CDC

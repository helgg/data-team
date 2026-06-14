# Patterns & Techniques — Data Engineering with AWS

## Pattern: Medallion Architecture (Raw → Curated → Consume)

**Quando usar:** toda data lake com múltiplos consumers e necessidade de qualidade progressiva de dados.

**Como:**
1. Raw zone (bronze): dados exatamente como chegaram da fonte; nunca deletar; Parquet ou formato original
2. Curated zone (silver): limpeza, deduplicação, conformação de schema, joins de referência; Parquet particionado
3. Consume zone (gold): agregações, data marts, modelos prontos para BI/ML; Parquet ou tabelas Redshift

**Trade-offs:** custo de storage × valor de reprocessamento (raw é reprocessável); latência adicional por zona.

---

## Pattern: ELT vs ETL

**Quando usar ELT:** destino é um DW poderoso (Redshift, BigQuery, Snowflake) com compute abundante; transformação em SQL é suficiente.
**Quando usar ETL:** transformações complexas requerem código (PySpark); necessidade de output em múltiplos destinos; fontes heterogêneas.

**Como (ELT):** extract → load raw → transform via SQL/dbt/Glue within DW
**Como (ETL):** extract → transform via Glue/EMR/Lambda → load curated

---

## Pattern: S3 Event-Driven Pipeline

**Quando usar:** processar arquivo imediatamente após upload; ingestão eventual de dados pontuais.

**Como:**
```
S3 upload → EventBridge rule → target (Lambda / SQS / Step Functions)
    → Lambda: transforma CSV → Parquet, escreve em S3 curated
```

**Trade-offs:** simples e serverless; não garante ordem de processamento; reprocessamento manual se Lambda falhar.

---

## Pattern: Streaming Ingestion com Kinesis + Firehose

**Quando usar:** dados chegam continuamente com latência < 60s necessária; volume alto e imprevisível.

**Como:**
```
Produtores → Kinesis Data Streams (shards) → Kinesis Firehose
    → S3 (buffer: 5 MB ou 300s, o que vier primeiro)
    → opcional: Firehose transforma via Lambda antes de escrever S3
```

**Trade-offs:** Firehose = at-least-once; sem reprocessamento nativo; KDS = reprocessável (retenção 24h–7d).

---

## Pattern: CDC com DMS (Change Data Capture)

**Quando usar:** replicar banco transacional para data lake sem impacto de carga; capturar atualizações e deleções.

**Como:**
1. DMS Full Load: carga inicial completa da tabela para S3
2. DMS CDC: monitora binary log do banco fonte; captura INSERT/UPDATE/DELETE
3. Glue ETL: aplica CDC ao Parquet no S3 (merge/upsert)
4. Alternativa com OTF: CDC diretamente para Iceberg/Hudi (record-level updates nativos)

**Trade-offs:** overhead de replicação no banco fonte; DMS não suporta todas as features específicas de banco; CDC + OTF elimina necessidade de merge manual.

---

## Pattern: SQS + Lambda (Decoupled Processing)

**Quando usar:** processar mensagens de uma fila de forma assíncrona; desacoplar produção de consumo; garantir retry automático.

**Como:**
```
Evento S3 / API / app → SQS queue
    → Lambda trigger (batch de N mensagens)
    → processar → deletar mensagens se sucesso
    → falha: mensagem retorna à fila após visibility timeout
```

**Trade-offs:** at-least-once delivery (design para idempotência); limite de 120K mensagens in-flight (usar double-queue para alto volume de arquivos pequenos).

---

## Pattern: Double-Queue (Netflix) para High-Volume S3 Events

**Quando usar:** volume de arquivos S3 excede quota de 120K mensagens in-flight do SQS; job downstream tem overhead fixo de inicialização.

**Como:**
```
S3 → EventBridge → SQS #1 (1 msg/arquivo, contém file_key + size)
    → Lambda A: acumula msgs até atingir batch ótimo (N GB)
              → escreve 1 msg em SQS #2 com lista de files
              → deleta msgs de SQS #1 (rápido: só processa metadata)
    → SQS #2 (1 msg = mouthful de N arquivos)
        → Lambda B / Glue: processa mouthful completo
```

**Trade-offs:** complexidade adicional de 2 filas + 2 Lambdas; reduz msgs em 90–99% na fila downstream.

---

## Pattern: Modular Pipeline com Store Intermediária (Spotify)

**Quando usar:** pipeline com múltiplas métricas/dimensões independentes para a mesma entidade (ex.: usuário, produto); cada métrica pode falhar/reprocessar independentemente.

**Como:**
```
Source data (S3/DW)
    → Job A: métrica_1 por entidade  (paralelo)
    → Job B: métrica_2 por entidade  (paralelo)
    → Job C: métrica_3 por entidade  (paralelo)
    → Store intermediária: DynamoDB / Redshift (chave = entidade)
        → Aggregação final: lê diretamente da store (sem re-scan da source)
```

**Trade-offs:** custo de storage intermediário; jobs independentes = debugging isolado + reprocessamento parcial.

---

## Pattern: Step Functions State Machine para Pipelines

**Quando usar:** pipeline com branches condicionais, paralelismo, retry automático com backoff, e integração nativa com serviços AWS.

**Como (estados comuns):**
```
Task: invocar Lambda / Glue / ECS / SageMaker
Choice: if/else baseado em resultado (ex.: sentiment NEGATIVE → notificar)
Parallel: rodar branches simultaneamente (ex.: múltiplos Glue jobs)
Map: iterar sobre array de inputs (ex.: processar lista de arquivos)
Wait: aguardar N segundos ou timestamp
```

**Trade-offs:** sem suporte nativo a histórico de runs (usar CloudWatch); ASL (JSON) verboso; melhor para pipelines event-driven; Airflow melhor para schedule-driven com dependências complexas.

---

## Pattern: Airflow DAG para Orquestração Schedule-Driven

**Quando usar:** pipeline com schedule diário/horário; dependências complexas entre tasks; necessidade de histórico visual de runs (UI Airflow).

**Como:**
```python
# Componentes de um DAG
- Operators: ação (PythonOperator, BashOperator, GlueJobOperator, RedshiftOperator)
- Sensors: esperar condição (S3KeySensor, ExternalTaskSensor)
- Hooks: conexão com serviços externos (S3Hook, PostgresHook)
- Dependencies: task_a >> task_b >> [task_c, task_d]
```

**Trade-offs:** MWAA = custo fixo de cluster; scheduling-based tem latência até próxima janela; melhor para pipelines batch previsíveis.

---

## Pattern: Redshift Distribution Strategy

**Quando usar:** otimizar performance de joins e evitar data movement entre nós.

**Como:**
- `EVEN`: distribuição round-robin entre nós; para tabelas sem join frequente
- `KEY(col)`: coloca linhas com mesmo valor de `col` no mesmo nó; para tabelas grandes que fazem join frequente na mesma coluna
- `ALL`: replica tabela em todos os nós; para tabelas de dimensão pequenas (< 1M linhas)

**Regra:** tabelas fato com KEY na coluna de join principal; dimensões com ALL se < 1M linhas; EVEN como default seguro.

---

## Pattern: COW vs MOR para OTFs

**Quando usar COW:** updates/deletes infrequentes; workload predominantemente read-heavy; simplicidade operacional; sem necessidade de compaction.

**Quando usar MOR:** streaming de alto volume (ex.: CDC contínuo); writes frequentes; pode tolerrar leituras ligeiramente mais lentas entre compactions.

**Regra operacional:** MOR exige compaction periódica em horário off-peak; sem compaction, performance de leitura degrada com acúmulo de delta logs.

---

## Pattern: OPTIMIZE → VACUUM (Iceberg)

**Quando usar:** manutenção periódica de tabelas Iceberg (semanal/mensal dependendo de volume de writes).

**Como (ordem obrigatória):**
```sql
-- 1. Primeiro: compactar e mesclar delete files
OPTIMIZE db.table REWRITE DATA USING BIN_PACK;

-- 2. Depois: deletar snapshots antigos
ALTER TABLE db.table SET TBLPROPERTIES ('vacuum_max_snapshot_age_seconds'='432000'); -- 5d
VACUUM db.table;
```

**Por que a ordem importa:** OPTIMIZE cria novo snapshot com dados compactados; VACUUM deleta snapshots antigos incluindo os não-otimizados; inverter a ordem pode deletar dados que OPTIMIZE ainda não processou.

---

## Pattern: DataZone Data Product Lifecycle

**Quando usar:** publicar e consumir data products em ambiente de data mesh AWS-native.

**Como:**
```
1. Data engineer: Glue Crawler registra tabela em curatedzonedb
2. Data producer (DataZone portal):
   - Importa data source (Glue database)
   - Aceita automated business names
   - Adiciona business metadata (descrição, glossário)
   - Publica data product
3. Data consumer (DataZone portal):
   - Cria projeto + environment (DataLakeProfile)
   - Busca catálogo por termo de negócio
   - Subscreve → razão de acesso
4. Data owner: aprova subscription
5. DataZone + Lake Formation: sharing automático (se managed asset)
6. Consumer: query via Athena (dados still no S3 do producer)
```

**Restrição:** unmanaged assets (sem Lake Formation permissions) → processo manual após aprovação.

---

## Pattern: IaC + CI/CD para Glue Jobs (DataOps)

**Quando usar:** todo Glue job em produção; qualquer mudança em infra de dados.

**Como:**
```
1. Developer edita script PySpark ou CloudFormation template
2. git add . && git commit && git push (CodeCommit)
3. CloudWatch Events detecta commit → CodePipeline inicia
   Pipeline A: CodeCommit → S3 (Glue script sincronizado)
   Pipeline B: CodeCommit → CloudFormation (Glue job atualizado)
4. Glue lê script atualizado do S3 na próxima execução
```

**Trade-offs:** setup inicial requer IAM roles (trust policy para cloudformation.amazonaws.com + glue.amazonaws.com); rollback = reverter commit.

---

## Pattern: AI Services Pipeline

**Quando usar:** processar dados não-estruturados (áudio, PDF, imagens, texto) sem expertise ML.

**Como (padrões comuns):**
```
Call center recordings → S3 → Transcribe → texto
    → Comprehend → sentiment/entities → DynamoDB/Redshift

PDF invoices → S3 → Textract → CSV (tables) / key-value (forms)
    → Glue ETL → curated zone → Redshift

Hotel reviews → SQS → Lambda → Comprehend detect_sentiment
    → Choice (Step Functions): NEGATIVE → notificar customer service
                               POSITIVE → terminar
```

**Regra:** AI Services = billing por uso (sem infra); SageMaker Autopilot = modelo customizado sem expertise ML; SageMaker full stack = controle total com expertise ML.

---

## Pattern: SageMaker ML Pipeline para Data Engineers

**Quando usar:** alimentar modelo ML em produção com dados atualizados na frequência correta.

**Como:**
```
Glue ETL (transform + aggregate) → S3 (feature store)
    → SageMaker Batch Transform (predição offline em batch)
        → S3 (resultado) → Redshift COPY → análise
    OU
    → SageMaker Endpoint (inference real-time)
        → aplicação chama endpoint via API
        → resultado em DynamoDB para acesso de baixa latência
```

**Responsabilidade do data engineer:** garantir que dados certos chegam ao modelo (pipeline reliability); não construir o modelo em si.

---

## Pattern: Athena Cost Management

**Quando usar:** qualquer ambiente com múltiplos times usando Athena (dev/prod isolation, cost attribution).

**Como:**
- Workgroups por ambiente (dev, prod) ou por time
- Limit: bytes scanned per query (`bytesScannedCutoffPerQuery`)
- Limit: bytes scanned per workgroup por dia
- Query result reuse: reutiliza resultado de query idêntica por N minutos
- Approximate COUNT DISTINCT: `approx_count_distinct()` em vez de COUNT DISTINCT para grandes volumes
- Particionar tabelas alinhado com predicados WHERE frequentes

---

## Técnica: Particionamento de Tabelas S3

**Quando usar:** tabelas com > 100 GB de dados; queries filtram por data, região, ou categoria frequentemente.

**Como:**
- Hive-style: `s3://bucket/prefix/year=2023/month=07/day=15/`
- Glue Crawler detecta partições automaticamente
- Iceberg nativo: partições ocultas (não precisam de nome de coluna no path)

**Regra:** particionar por coluna de filtro mais frequente; evitar cardinalidade muito alta (ex.: user_id como partição = milhões de partições = overhead de metadata).

---

## Técnica: Redshift COPY para Bulk Load

**Quando usar:** carregar arquivos S3 para Redshift de forma eficiente (COPY é 100x mais rápido que INSERT por linha).

**Como:**
```sql
COPY tabela FROM 's3://bucket/prefix/'
IAM_ROLE 'arn:aws:iam::account:role/RedshiftRole'
FORMAT AS PARQUET;  -- ou CSV, JSON, AVRO
```

**Otimizações:** múltiplos arquivos (1 por slice Redshift para paralelismo); Parquet > CSV (menos bytes scanned); compressão Snappy.

---

## Técnica: Glue DynamicFrame vs Spark DataFrame

**Quando usar DynamicFrame:** source tem schema inconsistente (tipos misturados por coluna); ingestão inicial de dados sujos.

**Quando usar DataFrame:** transformações Spark padrão; melhor performance; mais features Spark disponíveis.

**Como converter:**
```python
# DynamicFrame → DataFrame (para usar SQL/Spark API)
spark_df = dynamic_frame.toDF()
spark_df.createOrReplaceTempView("tabela")

# DataFrame → DynamicFrame (para escrever via getSink)
from awsglue.dynamicframe import DynamicFrame
dyf = DynamicFrame.fromDF(spark_df, glueContext, "ctx_name")
```

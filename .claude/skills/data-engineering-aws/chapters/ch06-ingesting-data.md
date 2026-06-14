# Chapter 6: Ingesting Batch and Streaming Data

## Core Idea
Ingestão não é simplesmente "copiar dados" — é escolher a ferramenta certa para o tipo, volume, velocidade e qualidade de cada fonte. Os 5 Vs (Variety, Volume, Velocity, Veracity, Value) fornecem o framework de análise antes de qualquer decisão técnica.

## Frameworks Introduced

- **5 Vs da Ingestão de Dados**
  - **Variety**: tipo de dado (estruturado/semi-estruturado/não estruturado) → define parser/extractor
  - **Volume**: tamanho histórico + crescimento diário → define se network transfer é viável ou precisa de Snow Family
  - **Velocity**: streaming contínuo vs batch agendado → define Kinesis/MSK vs DMS/Glue
  - **Veracity**: qualidade, completude e credibilidade → define necessidade de quality checks no pipeline
  - **Value**: dado serve ao objetivo do negócio? → valida se vale o custo de ingestão
  - Quando usar: deep dive com owner de cada fonte antes de definir toolset

- **Database Ingestion Decision Framework**
  - DB grande (>tens de GB): DMS com CDC contínuo — full load seria lento e sobrecarregaria produção
  - DB pequeno em RDS (MySQL/PostgreSQL/MariaDB): RDS snapshot export → S3 Parquet — zero load no DB
  - DB com transações constantes: DMS com read replica como fonte para minimizar impacto
  - DB com coluna crescente (audit log): Glue com Job Bookmarks — simples e sem CDC
  - DB muito grande sem boa rede: DMS + Snowball para carga inicial; depois CDC em real-time

- **Streaming Ingestion Decision Framework (Kinesis vs MSK)**
  - Kinesis: AWS-native, serverless (Firehose), sub-serviços especializados (Video Streams), integração forte com AWS
  - MSK: Apache Kafka gerenciado, ecossistema open-source, 200+ conectores, exatamente-uma-vez garantido
  - Decisão: se já tem Kafka/skills Kafka → MSK; se greenfield AWS → Kinesis; se precisa exactly-once → MSK

## Key Concepts

- **Structured data**: schema fixo, todas as linhas com mesmos campos e tipos; RDBMS, CSV, XLS
- **Semi-structured data**: schema flexível por registro; campos opcionais, nested (listas, objetos); JSON, XML; ideal para IoT, mobile, e-commerce com atributos variáveis por produto
- **Unstructured data**: sem schema pré-definido; texto livre, imagens, vídeo, áudio; requer ML/AI para extrair metadata utilizável para analytics
- **CDC (Change Data Capture)**: lê transaction logs do banco para capturar INSERTs, UPDATEs e DELETEs sem query full-table; DMS gera coluna `Op` (I/U/D) nos arquivos S3
- **DMS Replication Instance**: EC2 gerenciado que conecta ao endpoint de origem, lê dados e escreve no endpoint de destino; agora disponível em modo serverless (junho 2023)
- **Glue Job Bookmarks**: mecanismo que rastreia o maior valor de uma coluna-chave processada; próxima execução faz `WHERE key > last_value`; não detecta updates/deletes — ideal só para append-only tables
- **Kinesis Data Firehose buffer**: acumula dados antes de escrever no S3; configurável por tamanho (1–128 MB) OU tempo (60–900s) — o que for atingido primeiro dispara a escrita
- **Kinesis Shard (Data Streams)**: unidade de capacidade = 1 MB/s entrada + 2 MB/s saída; provisioned (manual) ou on-demand (auto)
- **MSK exactly-once**: configuração `processing.guarantee=exactly_once` em Apache Kafka ≥ 0.11; Kinesis oferece at-least-once (duplicatas possíveis — app deve tratar)
- **RDS Snapshot Export**: exporta todas as tabelas de um snapshot RDS para S3 em formato Parquet; zero impacto no DB de produção; suporta MySQL, PostgreSQL, MariaDB; não serve para replicação real-time
- **Kinesis Agent**: software open-source instalável em servidores on-premises; monitora arquivos de log e faz stream para Kinesis Firehose ou Data Streams sem modificar a aplicação
- **Amazon KDG (Kinesis Data Generator)**: ferramenta open-source da AWS que roda no browser; gera dados de teste com templates Handlebars e envia para Kinesis
- **Dynamic Partitioning (Firehose)**: particionar dados no S3 com base em campos do payload em tempo de ingestão (ex.: por estado, por tipo de evento)
- **CloudFormation**: infraestrutura como código em JSON/YAML; permite deploy reproduzível e versionável de recursos AWS; SakilaDB foi deploiada via CFN template no hands-on

## Reference Tables

### Tipos de dados e características

| Tipo | Schema | Exemplos | Desafio |
|------|--------|----------|---------|
| Estruturado | Fixo, pré-definido | RDBMS, CSV, XLS | Fácil de ingerir; difícil combinar fontes com schemas diferentes |
| Semi-estruturado | Flexível por registro | JSON, XML | Nested fields; campos opcionais; requer parser |
| Não estruturado | Nenhum | Imagem, vídeo, texto livre, PDF | Analytics direto impossível; requer extração de metadata via ML |

### Ferramentas de ingestão de banco — quando usar

| Ferramenta | Quando usar | Limitação |
|-----------|-------------|-----------|
| **AWS DMS** | CDC contínuo; migração de qualquer RDBMS → S3; grandes DBs | Requer binary logging habilitado; pode impactar DB se sem read replica |
| **DMS Serverless** | CDC sem querer gerenciar EC2 de replicação | Lançado jun/2023; menos controle de configuração |
| **DMS + Snowball** | DB muito grande com rede limitada para carga inicial | Semanas para carga inicial + aplicação de CDC acumulado |
| **AWS Glue + Bookmarks** | Tabelas append-only com coluna crescente (audit logs, IDs sequenciais) | Não detecta updates/deletes |
| **RDS Snapshot Export** | MySQL/PostgreSQL/MariaDB em RDS; export diário completo | Apenas RDS; sem real-time; zero load no DB |
| **EMR + JDBC** | Spark job com lógica customizada; ecossistema Hadoop necessário | Mais configuração |
| **Lake Formation Blueprint** | Pipeline simples com Glue; low-code setup | Apenas fontes suportadas pelo Glue |

### Kinesis vs MSK — comparação

| Critério | Amazon Kinesis | Amazon MSK |
|---------|---------------|------------|
| Tipo | Proprietário AWS | Apache Kafka gerenciado |
| Modo serverless | Firehose (nativo), Data Streams (on-demand) | MSK Serverless (limitado) |
| Configuração | Mínima | Provisioned: EC2 type, storage, Kafka version, VPC |
| Exactly-once | Não — at-least-once (app deve tratar duplicatas) | Sim — `processing.guarantee=exactly_once` |
| Connectors | AWS services + Splunk, DataDog, MongoDB, etc. | 200+ Kafka connectors open-source |
| Sub-serviços especializados | Video Streams, Data Analytics (Flink) | Único serviço |
| Escolher quando | Greenfield AWS; simplicidade; sub-serviços especializados | Kafka existente; exactly-once; fine-tuning; ecossistema open-source |

### DMS — fatores de decisão por tamanho de DB

| Cenário | Abordagem recomendada |
|---------|----------------------|
| DB < ~10 GB em RDS | RDS Snapshot Export → S3 Parquet (mais simples) |
| DB pequeno não-RDS | Glue full load noturno ou DMS one-time |
| DB médio com updates/deletes | DMS CDC com read replica como fonte |
| DB grande (>100 GB) | DMS full load inicial + CDC contínuo |
| DB enorme sem boa rede | DMS + Snowball carga inicial + CDC durante transporte |

## Worked Example

**Hands-on Ch06 — Pipeline completa: MySQL → S3 → Athena + Kinesis Firehose → S3 → Athena**

**Parte 1: DMS MySQL → S3 (Sakila DB)**

Setup via CloudFormation:
```yaml
# mysql-ec2loader.cfn cria:
# - RDS MySQL t3.micro (20 GB)
# - EC2 t3.micro que baixa e carrega SakilaDB no MySQL
```

IAM policy mínima para DMS escrever no S3:
```json
{
  "Effect": "Allow",
  "Action": ["s3:*"],
  "Resource": [
    "arn:aws:s3:::dataeng-landing-zone-<initials>",
    "arn:aws:s3:::dataeng-landing-zone-<initials>/*"
  ]
}
```

Configuração DMS task:
- Source: MySQL RDS endpoint (+ `AddColumnName=True` no target para preservar headers)
- Target: S3 landing zone, prefix `sakila-db/`
- Migration type: **Migrate existing data** (full load one-time)
- Table mapping: schema `%sakila%`, todas as tabelas

Após carga: Lambda (do Ch03) converte CSV→Parquet no clean zone automaticamente via S3 trigger.

Query de validação:
```sql
-- Athena, database: sakila
SELECT * FROM film LIMIT 20;
```

**Parte 2: Kinesis Firehose streaming → S3**

Configuração Firehose:
- Source: Direct PUT
- Destination: S3 landing zone
- Prefix: `streaming/!{timestamp:yyyy/MM/}`
- Error prefix: `!{firehose:error-output-type}/!{timestamp:yyyy/MM/}`
- Buffer: 1 MB OU 60 segundos (o que vencer primeiro)

Template KDG para simular streaming de parceiros de distribuição de filmes:
```json
{
  "timestamp": "{{date.now}}",
  "eventType": "{{random.weightedArrayElement({\"weights\":[0.3,0.1,0.6],\"data\":[\"rent\",\"buy\",\"trailer\"]})}}",
  "film_id": {{random.number({"min":1,"max":1000})}},
  "distributor": "{{random.arrayElement([\"amazon prime\",\"google play\",\"apple itunes\"])}}",
  "platform": "{{random.arrayElement([\"ios\",\"android\",\"xbox\",\"smart tv\"])}}",
  "state": "{{address.state}}"
}
```

Após 5–10 min (3.000–6.000 registros): Glue Crawler → `streaming_db` → Athena:
```sql
SELECT * FROM streaming LIMIT 20;
```

**Resultado**: dois datasets no data lake (sakila relacional via DMS + streaming de eventos via Kinesis) prontos para joins em Ch07.

## Key Takeaways

1. Avaliar os 5 Vs de cada fonte antes de escolher ferramenta — velocity decide batch vs streaming; volume decide network vs Snow Family
2. DMS para CDC contínuo de qualquer RDBMS; RDS Snapshot Export para simplicidade máxima em RDS MySQL/PostgreSQL/MariaDB
3. Glue Job Bookmarks funciona apenas para append-only tables — nunca usar onde rows são atualizados ou deletados
4. Kinesis para greenfield AWS-native; MSK quando já existe Kafka, precisa de exactly-once, ou ecossistema open-source é crítico
5. Envolver o DBA owner da fonte no início — CDC requer binary logging com configurações específicas; descobrir isso tarde causa atrasos críticos
6. Firehose buffer: tamanho OU tempo — o primeiro atingido escreve no S3; para dados de baixo volume, configurar buffer interval pequeno para não esperar muito
7. Lambda trigger em S3 (do Ch03) pode automatizar CSV→Parquet no clean zone sem orquestrador adicional

## Connects To

- **Ch03**: Lambda CSV→Parquet (disparada por S3 trigger do DMS output) + Glue Data Catalog
- **Ch04**: PII tokenization deve ocorrer neste estágio — antes de prosseguir para clean zone
- **Ch05**: Fontes identificadas no whiteboard do Projeto Bright Light são concretizadas aqui
- **Ch07**: Dados ingeridos (Sakila + streaming) são transformados e otimizados para analytics
- **Ch09**: Subset de dados curated carregado no Redshift para data mart de BI
- **Ch14**: Formatos transacionais (Iceberg/Hudi) — alternativa ao padrão CSV→Parquet para CDC com ACID

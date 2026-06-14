# Skill: Data Engineering with AWS

**Livro:** Data Engineering with AWS (2nd Edition) — Gareth Eagar
**Idioma:** pt-BR (termos técnicos preservados em inglês)
**Gerado:** 2026-06

---

## Como usar esta skill

Use `DEPTH=study` com exemplos de código e worked examples nos capítulos. Responda sempre com voz de praticante: "Use X quando Y", não "o livro diz...".

Para consultas: leia o `SKILL.md` → identifique capítulos relevantes pelo Topic Index → leia os `chapters/chNN-*.md` → responda exclusivamente do conteúdo dos arquivos.

Se o tópico não estiver coberto: *"Not covered in `data-engineering-aws`. Topics available: [lista do Topic Index]."*

---

## Core Frameworks

### 1. Medallion Architecture (Raw → Curated → Consume)
Zonas progressivas de qualidade de dados. Raw = imutável (dado exato da fonte). Curated = limpo, conformado, Parquet particionado. Consume = agregado, pronto para BI/ML. Cada zona é reprocessável a partir da anterior. → Ch02, Ch05

### 2. ETL vs ELT Decision
ETL: transformação antes de carregar; necessário para fontes heterogêneas, lógica complexa, múltiplos destinos. ELT: carrega raw primeiro, transforma no DW via SQL; ideal quando destino tem compute abundante (Redshift, Snowflake). → Ch01

### 3. Batch vs Streaming Decision
Batch: latência tolerável (minutos a horas), custo menor, ferramentas: DMS/AppFlow/Glue. Streaming: latência sub-segundo a segundos, custo maior, ferramentas: Kinesis Data Streams/Firehose/MSK. → Ch01, Ch06

### 4. COW vs MOR para OTFs
COW: reescreve arquivo inteiro no update; leituras rápidas, escritas lentas; use para workloads read-heavy. MOR: appenda delta log; escritas rápidas, leituras requerem merge; use para CDC/streaming de alto volume; requer compaction periódica. → Ch14

### 5. Build vs Buy vs SDLF
Buy (Databricks/Snowflake): plataforma integrada, sem DevOps, custo premium, multi-cloud. Build (AWS-native): flexível, custo menor, requer DevOps, ideal para ambientes heterogêneos. SDLF: headstart com best practices, requer DevOps, acelerador (não alternativa ao Buy). → Ch16

### 6. Data Mesh — 4 Princípios de Dehghani
(1) Domain-oriented, decentralized data ownership. (2) Data as a product (SLA, docs, qualidade). (3) Self-service data infrastructure as a platform. (4) Federated computational governance (padrões mínimos + automação de compliance). → Ch15

### 7. DataOps = Automation + Observability
Automation: IaC (CloudFormation/CDK) + SCM (CodeCommit) + CI/CD (CodePipeline/CodeBuild). Observability: dashboards (CloudWatch) + alerts (CloudWatch Alarms, Airflow SLAs) + logs (CloudWatch Logs, OpenSearch). Sem DataOps, platform em produção não é sustentável. → Ch16

---

## AWS Service Map — Decisão Rápida

| Necessidade | Serviço Principal | Alternativa |
|------------|------------------|-------------|
| Data lake storage | S3 + Parquet | — |
| Data warehouse | Redshift RA3 | Redshift Serverless |
| OTF (transactional lake) | Apache Iceberg | Apache Hudi, Delta Lake |
| Batch ETL (Spark) | AWS Glue ETL | EMR (mais controle) |
| Transformação no-code | DataBrew | — |
| Streaming ingestion | Kinesis Firehose | MSK (Kafka) |
| Replicação de banco | DMS (CDC) | Glue (S3→S3) |
| SaaS ingestion | AppFlow | — |
| On-premises | DataSync | — |
| Ad-hoc SQL sobre S3 | Athena | Redshift Spectrum |
| BI / dashboards | QuickSight | — |
| Orquestração event-driven | Step Functions | EventBridge + Lambda |
| Orquestração schedule-driven | MWAA (Airflow) | Step Functions |
| Access control granular | Lake Formation | IAM (menos granular) |
| Business data catalog | DataZone | Collibra (multi-vendor) |
| Technical metadata catalog | Glue Data Catalog | — |
| PII detection | Amazon Macie | — |
| ML pipeline | SageMaker | — |
| AI pré-treinado (texto/voz/imagem) | Comprehend/Transcribe/Rekognition | — |
| Generative AI / LLMs | Amazon Bedrock | SageMaker JumpStart |
| IaC | CloudFormation | Terraform (multi-cloud) |
| IaC com linguagem de programação | AWS CDK | Pulumi |
| CI/CD | CodePipeline | GitHub Actions |

---

## Topic Index

| Tópico | Capítulos |
|--------|-----------|
| Arquitetura de data lake (zones, medallion) | Ch02, Ch05 |
| Arquitetura de data warehouse | Ch02, Ch09 |
| Data lakehouse / OTFs | Ch02, Ch14 |
| AWS services overview (toolkit) | Ch03 |
| Data governance, segurança, catálogo | Ch04 |
| Lake Formation (access control, sharing) | Ch04, Ch15 |
| Amazon Macie (PII detection) | Ch04 |
| Design de pipelines de dados | Ch05 |
| Ingestão batch (DMS, AppFlow, DataSync, Glue) | Ch06 |
| Ingestão streaming (Kinesis, MSK) | Ch06 |
| Transformação de dados (Glue ETL, DataBrew, EMR) | Ch07 |
| Formato Parquet, particionamento, compressão | Ch07 |
| Glue DynamicFrame vs Spark DataFrame | Ch07 |
| Data consumers (QuickSight, Athena, Redshift, SageMaker) | Ch08 |
| Amazon Redshift (arquitetura, distribuição, sort keys) | Ch09 |
| Redshift RA3, Serverless, Spectrum | Ch09 |
| Redshift COPY, materialized views, Redshift ML | Ch09 |
| Step Functions (ASL, estados) | Ch10 |
| Apache Airflow / MWAA (DAG, Operators, Sensors) | Ch10 |
| Orchestração event-driven vs schedule-driven | Ch10 |
| Amazon Athena (workgroups, federated query, custo) | Ch11 |
| Athena para Apache Spark | Ch11 |
| Amazon QuickSight (SPICE, ML Insights, QuickSight Q) | Ch12 |
| QuickSight Generative BI | Ch12, Ch17 |
| ML/AI na AWS — visão geral | Ch13 |
| SageMaker (ciclo completo de ML) | Ch13 |
| AI Services (Transcribe, Textract, Comprehend, Rekognition) | Ch13 |
| Amazon Bedrock / Foundation Models / LLMs | Ch13 |
| Open Table Formats (Delta Lake, Hudi, Iceberg) | Ch14 |
| ACID em data lakes | Ch14 |
| Time travel, schema evolution | Ch14 |
| OPTIMIZE e VACUUM (Iceberg) | Ch14 |
| Data mesh — princípios e organização | Ch15 |
| Amazon DataZone (domínios, catálogo, sharing) | Ch15 |
| Cross-account sharing via Lake Formation | Ch15 |
| Modern data platform — goals e componentes | Ch16 |
| Build vs Buy vs SDLF | Ch16 |
| DataOps (IaC, CI/CD, observability) | Ch16 |
| CloudFormation, CDK, CodeCommit, CodeBuild, CodePipeline | Ch16 |
| SDLF (Serverless Data Lake Framework) | Ch16 |
| Real-world pipelines (Spotify, Netflix) | Ch17 |
| Tendências emergentes (multi-cloud, FinOps, GenAI) | Ch17 |
| FinOps e cost optimization | Ch16, Ch17 |
| Migração para OTFs | Ch14, Ch17 |

---

## Chapter Index

| # | Arquivo | Tópico principal |
|---|---------|-----------------|
| 01 | [ch01-intro-data-engineering.md](chapters/ch01-intro-data-engineering.md) | O que é data engineering; ETL vs ELT; batch vs streaming; roles; AWS account setup |
| 02 | [ch02-data-management-architectures.md](chapters/ch02-data-management-architectures.md) | Data lake, data warehouse, data mart, data lakehouse; medallion architecture; data swamp |
| 03 | [ch03-aws-toolkit.md](chapters/ch03-aws-toolkit.md) | AWS services para data engineering: S3, IAM, Lambda, Glue, EMR, Kinesis, MSK, Redshift, Athena, QuickSight, Step Functions, MWAA, Lake Formation |
| 04 | [ch04-data-governance.md](chapters/ch04-data-governance.md) | Governança, segurança, catálogo; IAM, KMS, Lake Formation, Glue Data Catalog, Amazon Macie, CloudTrail |
| 05 | [ch05-architecting-pipelines.md](chapters/ch05-architecting-pipelines.md) | Design de pipelines; zones (raw/curated/consume); batch vs streaming decision; SLA; data quality |
| 06 | [ch06-ingesting-data.md](chapters/ch06-ingesting-data.md) | Ingestão batch (DMS CDC, AppFlow, DataSync) e streaming (Kinesis Data Streams, Firehose, MSK); at-least-once vs exactly-once |
| 07 | [ch07-transforming-data.md](chapters/ch07-transforming-data.md) | Glue ETL (PySpark, DynamicFrame), DataBrew (no-code), EMR, Lambda; Parquet, particionamento, compressão; Glue Studio |
| 08 | [ch08-data-consumers.md](chapters/ch08-data-consumers.md) | Tipos de consumers; QuickSight (BI), Athena (ad-hoc), Redshift (DW), SageMaker (ML); S3 Select; Athena Federated Query |
| 09 | [ch09-data-marts-redshift.md](chapters/ch09-data-marts-redshift.md) | Amazon Redshift arquitetura (RA3, Serverless); distribution styles; sort keys; COPY; Spectrum; materialized views; Redshift ML; data shares |
| 10 | [ch10-orchestrating-pipelines.md](chapters/ch10-orchestrating-pipelines.md) | Step Functions (ASL, estados); MWAA/Airflow (DAG, Operators, Sensors, Hooks); EventBridge; Lambda como orquestrador |
| 11 | [ch11-athena-ad-hoc.md](chapters/ch11-athena-ad-hoc.md) | Athena workgroups; federated query; approx aggregates (HLL); query result reuse; Athena for Spark; cost management |
| 12 | [ch12-quicksight-visualization.md](chapters/ch12-quicksight-visualization.md) | QuickSight SPICE; Standard vs Enterprise; analysis vs dashboard; ML Insights; QuickSight Q (NLQ); Generative BI; embedded dashboards |
| 13 | [ch13-ai-ml.md](chapters/ch13-ai-ml.md) | AWS ML stack (3 camadas); SageMaker (Ground Truth, Wrangler, Clarify, Autopilot, JumpStart, Experiments, Endpoints, Model Monitor); AI Services; Amazon Bedrock; Foundation Models |
| 14 | [ch14-transactional-data-lakes.md](chapters/ch14-transactional-data-lakes.md) | OTFs (Delta Lake, Hudi, Iceberg); COW vs MOR; ACID; time travel; schema evolution; OPTIMIZE + VACUUM; Athena + Iceberg hands-on |
| 15 | [ch15-data-mesh.md](chapters/ch15-data-mesh.md) | Data mesh (4 princípios Dehghani); Amazon DataZone (domains, glossaries, metadata forms, portal, projects); Lake Formation cross-account sharing; arquiteturas AWS-native vs multi-vendor |
| 16 | [ch16-modern-data-platform.md](chapters/ch16-modern-data-platform.md) | Build vs Buy vs SDLF; DataOps (IaC + CI/CD + observability); CloudFormation, CDK, CodeCommit, CodeBuild, CodePipeline; SDLF (Foundation/Teams/Datasets/Pipelines/Transformations) |
| 17 | [ch17-wrap-up.md](chapters/ch17-wrap-up.md) | Complexidade real (multi-team, multi-env); Spotify Wrapped (modular pipeline + store intermediária); Netflix VPC Flow Logs (double-queue pattern); tendências emergentes (data mesh, multi-cloud, OTFs, FinOps, GenAI para BI e ETL) |

---

## Support Files

| Arquivo | Conteúdo |
|---------|---------|
| [glossary.md](glossary.md) | Todos os termos técnicos com definição e referência de capítulo |
| [patterns.md](patterns.md) | Design patterns e técnicas reutilizáveis com trade-offs |
| [cheatsheet.md](cheatsheet.md) | Tabelas de decisão rápida por cenário + checklists |

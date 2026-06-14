# Cheatsheet — Data Engineering with AWS

## Decisão: Qual serviço de ingestão usar?

| Fonte | Volume | Latência | Serviço recomendado |
|-------|--------|----------|---------------------|
| Banco relacional (migração) | Qualquer | Batch | DMS Full Load |
| Banco relacional (replicação contínua) | Qualquer | Near-real-time | DMS CDC |
| SaaS (Salesforce, SAP, Marketo) | Qualquer | Batch/event | AppFlow |
| On-premises (NFS, SMB, HDFS) | TB–PB | Batch | DataSync |
| S3 para S3 (transform + copy) | Qualquer | Batch | Glue ETL |
| Eventos em tempo real (alta vazão) | Alto | Sub-segundo | Kinesis Data Streams |
| Streaming com delivery gerenciado | Alto | Segundos | Kinesis Firehose |
| Kafka (compatibilidade ecossistema) | Alto | Sub-segundo | MSK |
| Arquivos pequenos, trigger de evento | Baixo | Sub-segundo | Lambda |

---

## Decisão: Qual serviço de transformação usar?

| Caso de uso | Serviço | Quando NÃO usar |
|-------------|---------|-----------------|
| PySpark / SQL em batch | AWS Glue ETL | Transformações < 2s (overhead de inicialização) |
| Transformação visual no-code | DataBrew | Transformações complexas em código |
| Spark/Presto/Flink com controle total | EMR | Quando serverless é suficiente |
| Transformação leve event-driven | Lambda | Lógica complexa, > 15 min de execução |
| SQL sobre S3 ad-hoc | Athena | Writes frequentes (use Glue) |

---

## Decisão: Qual storage usar?

| Tipo de dado | Volume | Padrão de acesso | Storage recomendado |
|-------------|--------|-----------------|---------------------|
| Analytics (lake) | TB–PB | Batch/scan | S3 + Parquet |
| Analytics (DW) | GB–TB | SQL, joins complexos | Redshift RA3 |
| Analytics (lake com ACID) | TB–PB | Update/delete frequentes | S3 + Iceberg |
| Acesso por chave primária < 10ms | Qualquer | Point lookup | DynamoDB |
| Full-text search / logs | GB–TB | Busca textual | OpenSearch |
| Dados transacionais | GB–TB | OLTP | RDS / Aurora |

---

## Decisão: Qual Open Table Format (OTF) usar?

| Critério | Delta Lake | Apache Hudi | Apache Iceberg |
|---------|-----------|-------------|----------------|
| AWS Athena write nativo | ✗ | ✗ | ✅ |
| Record-level index | ✗ | ✅ | ✗ |
| Shallow clone | ✅ | ✗ | ✗ |
| Z Ordering | ✅ | ✗ | ✗ |
| Change Data Feed | ✅ | Incremental | ✗ |
| Momentum AWS / vendors | Médio | Médio | **Alto** |
| Multiformat (Parquet+ORC+Avro) | ✗ | ✅ | ✅ |

**Regra geral:** use Iceberg em novos projetos AWS-native; use Hudi se record-level index é crítico; use Delta Lake se stack é Databricks-centric.

---

## Decisão: COW vs MOR

| Critério | COW | MOR |
|---------|-----|-----|
| Updates/deletes frequentes | ✗ lento | ✅ rápido |
| Queries de leitura | ✅ rápido | ✗ lento (até compaction) |
| Overhead operacional | Baixo | Médio (compaction) |
| Streaming CDC | ✗ | ✅ |
| Workload read-heavy | ✅ | ✗ |

---

## Decisão: Qual orquestrador usar?

| Critério | Step Functions | Airflow (MWAA) | EventBridge |
|---------|---------------|----------------|-------------|
| Trigger | Evento / API | Schedule (cron) | Evento AWS |
| Branches condicionais | ✅ ASL Choice | ✅ Python BranchOperator | ✗ |
| Retry com backoff | ✅ nativo | ✅ nativo | ✗ |
| Visualização de histórico | CloudWatch | ✅ UI Airflow | CloudWatch |
| Dependências entre DAGs | ✗ | ✅ ExternalTaskSensor | ✗ |
| Custo | Por state transition | Cluster fixo (MWAA) | Por evento |
| Ideal para | Event-driven, serverless | Schedule-driven, complex deps | Trigger simples |

---

## Decisão: Athena vs Redshift — quando usar cada

| Cenário | Use Athena | Use Redshift |
|---------|-----------|--------------|
| Query ad-hoc sobre S3 | ✅ | ✗ (COPY seria necessário) |
| Dashboard com < 30s de latência | ✅ (com SPICE/cache) | ✅ |
| Joins complexos de múltiplos TB | ✗ (lento) | ✅ (colunar otimizado) |
| Custo por query (sem cluster idle) | ✅ | ✗ |
| Transformação Iceberg (write) | ✅ | ✗ parcial |
| Data mart com schema fixo | ✗ | ✅ |
| Federated query (DynamoDB, RDS, etc.) | ✅ Athena Federated | ✗ |

---

## Decisão: Build vs Buy vs SDLF

| Critério | Buy (Databricks/Snowflake) | Build (AWS-native) | SDLF |
|---------|--------------------------|-------------------|------|
| DevOps skills | Não necessário | Necessário | Necessário |
| Custo | Premium | Menor | Menor |
| Multi-cloud | ✅ | ✗ | ✗ |
| Vendor lock-in | Alto | Baixo | Baixo |
| Time de implementação | Curto | Longo | Médio |
| Ideal para | Mid-size sem DevOps | Enterprises heterogêneas | Headstart com best practices |

---

## Decisão: Qual AI Service AWS usar?

| Necessidade | Serviço | Billing |
|------------|---------|---------|
| Transcrever áudio → texto | Amazon Transcribe | Por segundo de áudio |
| Extrair texto de PDF/imagem | Amazon Textract | Por página |
| Sentiment, entidades, PII de texto | Amazon Comprehend | Por 100 chars |
| Labels, faces, objetos em imagem/vídeo | Amazon Rekognition | Por imagem / min de vídeo |
| Forecast de séries temporais | Amazon Forecast | Por dataset + predição |
| Detecção de fraude | Amazon Fraud Detector | Por evento |
| Recomendações personalizadas | Amazon Personalize | Por evento + predição |
| Chatbot / geração de conteúdo / código | Amazon Bedrock | Por token |
| Modelo customizado sem expertise ML | SageMaker Autopilot | Por job de treino + endpoint |

---

## Decisão: SageMaker — qual ferramenta de preparação usar?

| Necessidade | Ferramenta |
|------------|-----------|
| Labeling de dados para ML supervisionado | Ground Truth |
| Transformação visual sem código | Data Wrangler |
| Detecção de bias no dataset | Clarify |
| Treinar modelo sem escrever código | Autopilot |
| Usar foundation model pré-treinado | JumpStart |
| Inference em batch sobre S3 | Batch Transform |
| Inference em real-time < 100ms | Endpoint |
| Monitorar drift de qualidade em produção | Model Monitor |

---

## Decisão: Qual distribuição Redshift usar?

| Cenário | Distribution Style |
|---------|------------------|
| Tabela sem join frequente | EVEN |
| Tabela fato com join frequente por 1 coluna | KEY(coluna_join) |
| Tabela dimensão < 1M linhas | ALL |
| Tabela dimensão > 1M linhas | KEY ou EVEN |

---

## Decisão: Redshift RA3 vs Serverless

| Critério | RA3 (provisionado) | Redshift Serverless |
|---------|-------------------|---------------------|
| Workload previsível e constante | ✅ (custo fixo) | ✗ |
| Workload intermitente | ✗ (paga idle) | ✅ |
| Controle de configuração | Total | Limitado |
| Custo mínimo | Fixo por hora | Zero quando idle |
| Data shares (cross-account) | ✅ | ✅ |

---

## Decisão: DataZone vs alternativas de catálogo

| Cenário | Solução |
|---------|--------|
| 100% AWS-native (S3 + Redshift) | Amazon DataZone (sharing automático) |
| Multi-vendor (Snowflake + Databricks + AWS) | Collibra / Atlan / Alation |
| Data lineage necessário | Collibra / Atlan (DataZone não suporta) |
| Apenas sharing, sem catálogo sofisticado | Lake Formation diretamente |
| Startup/pequena org iniciando data mesh | AWS-native + DataZone |

---

## Regras de ouro de custo

| Serviço | Otimização de custo |
|---------|-------------------|
| Athena | Particionar tabelas; Parquet > CSV; reutilizar query results; workgroups com byte limit |
| Glue | Auto-scaling habilitado; ajustar NumberOfWorkers; G.1X para jobs simples |
| Redshift | RA3 para workloads constantes; Serverless para intermitentes; Spectrum para dados frios em S3 |
| S3 | Lifecycle rules (Standard → IA → Glacier); Intelligent Tiering para acesso imprevisível |
| Kinesis Data Streams | On-demand para throughput imprevisível; provisioned para throughput estável |
| SageMaker | Batch Transform > Endpoint quando latência real-time não é necessária |

---

## Operações de manutenção Iceberg (sequência)

```sql
-- 1. Compactar small files e mesclar delete files
OPTIMIZE db.table REWRITE DATA USING BIN_PACK;

-- 2. Configurar retenção de snapshots (opcional)
ALTER TABLE db.table SET TBLPROPERTIES ('vacuum_max_snapshot_age_seconds'='432000');

-- 3. Deletar snapshots antigos e arquivos orfãos
VACUUM db.table;
```

---

## Checklist: Data Platform MVP

- [ ] Storage: S3 com zones (raw/curated/consume), Lifecycle rules, encriptação KMS
- [ ] Catalog: Glue Data Catalog + DataZone para business metadata
- [ ] Access control: Lake Formation com column/row permissions
- [ ] Ingestão: DMS (relacional) ou Kinesis/Firehose (streaming) ou AppFlow (SaaS)
- [ ] Transformação: Glue ETL com Parquet + particionamento adequado
- [ ] Governança: Macie para PII scan, CloudTrail para auditoria
- [ ] Orquestração: Step Functions (event-driven) ou MWAA (schedule-driven)
- [ ] Observability: CloudWatch Dashboards + Alarms + Logs
- [ ] IaC: CloudFormation ou Terraform para todos os recursos
- [ ] CI/CD: CodeCommit + CodePipeline para código e infra

---

## Checklist: DataOps mínimo para produção

- [ ] Código em SCM (CodeCommit/GitHub), nunca editado direto no console
- [ ] Infraestrutura como código (CloudFormation/CDK)
- [ ] Pipeline CI/CD (CodePipeline): commit → deploy automático
- [ ] Testes unitários (CodeBuild) antes de deploy
- [ ] Dashboard de saúde (CloudWatch ou Airflow UI)
- [ ] Alertas para falhas (CloudWatch Alarms ou Airflow SLAs)
- [ ] Logs centralizados (CloudWatch Logs ou OpenSearch)
- [ ] Billing alarm configurado na conta AWS

---

## Manutenção de tabelas OTF — frequência recomendada

| Volume de writes | OPTIMIZE | VACUUM |
|-----------------|---------|--------|
| < 10K registros/dia | Semanal | Mensal |
| 10K–1M registros/dia | Diário | Semanal |
| > 1M registros/dia | Por hora (off-peak) | Diário |
| CDC contínuo (MOR) | Off-peak (compaction) | Após compaction |

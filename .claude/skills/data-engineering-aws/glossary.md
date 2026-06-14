# Glossário — Data Engineering with AWS

**ACID** — propriedades de transação: Atomicity (tudo ou nada), Consistency (estado válido antes e depois), Isolation (transações concorrentes não se interferem), Durability (commit persiste). Resolvido em data lakes pelos OTFs. (Ch14)

**Amazon Athena** — query engine serverless para S3; SQL padrão; suporte completo a Apache Iceberg (read+write+OPTIMIZE+VACUUM); Federated Query para fontes externas; cobrança por dados escaneados. (Ch11, Ch14)

**Amazon Bedrock** — serviço serverless de Foundation Models (Claude, AI21 Labs, Cohere, Meta, Stability AI, Amazon Titan) via API unificada; fine-tune privado sem expor dados ao provider. (Ch13)

**Amazon CodeWhisperer** — AI coding companion integrado ao Glue Studio Notebooks; gera código PySpark a partir de comentários em linguagem natural. (Ch17)

**Amazon DataZone** — business data catalog com funcionalidade de data mesh; lançado outubro 2023; domains, data sources (Glue + Redshift), business glossaries, metadata forms, data portal (SSO via Identity Center), projects e environments (DataLakeProfile). (Ch15)

**Amazon EMR** — Elastic MapReduce; cluster gerenciado para Apache Spark, Hadoop, Presto, Trino, Flink; suporte nativo a OTFs (Delta Lake, Hudi, Iceberg) desde EMR 6.9.0. (Ch03, Ch14)

**Amazon Kinesis Data Streams** — streaming de alto throughput com shards; retenção de 24h (padrão) a 7 dias; at-least-once delivery; consumido por Lambda, Kinesis Analytics, Dredge (Netflix). (Ch06)

**Amazon Kinesis Firehose** — delivery stream managed; carrega dados de Kinesis Data Streams ou diretamente para S3/Redshift/OpenSearch/Splunk; buffering configurable (size + time). (Ch06)

**Amazon Lake Formation** — serviço de access control granular para data lakes; permissões column-level e row-level sobre tabelas no Glue Catalog; cross-account sharing sem copiar dados; base técnica do data mesh no AWS. (Ch04, Ch15)

**Amazon Macie** — serviço gerenciado para detecção de PII em objetos S3; classifica dados automaticamente por tipo de sensibilidade. (Ch04, Ch16)

**Amazon MWAA** — Managed Workflows for Apache Airflow; orquestrador gerenciado; DAGs em S3; suporte a todas as integrações nativas do Airflow. (Ch10)

**Amazon QuickSight** — ferramenta de BI gerenciada; SPICE para in-memory acceleration; Standard vs Enterprise editions; ML Insights (anomaly detection, forecasting, autonarratives); QuickSight Q para NLQ; Generative BI para stories automáticas. (Ch12)

**Amazon Redshift** — data warehouse colunar gerenciado; nós RA3 com managed storage (compute separado de storage); Serverless; Spectrum para query S3 lake; Redshift ML (CREATE MODEL via SageMaker AutoML); data shares via Lake Formation. (Ch09)

**Amazon SageMaker** — plataforma ML end-to-end; fases: Ground Truth (labeling), Data Wrangler (prep visual), Clarify (bias detection), Autopilot (AutoML), JumpStart (soluções pré-construídas), Batch Transform, Endpoints (real-time inference), Model Monitor (drift detection). (Ch13)

**Apache Airflow DAG** — Directed Acyclic Graph; unidade de pipeline no Airflow; define tasks, dependências e schedule; composto por Operators, Sensors, Hooks e Connections. (Ch10)

**Apache Hudi** — Open Table Format criado no Uber (2016); Apache top-level (2020); HDFS Updates Deletes and Incrementals; destaque: record-level index único entre OTFs (localiza arquivo exato sem scan); suporta COW e MOR; compaction periódica necessária em MOR. (Ch14)

**Apache Iceberg** — Open Table Format criado na Netflix; Apache top-level (2021); maior momentum de adoção e suporte de vendors; hierarquia de metadata (catalog → metadata.json → manifest list → manifest files → Parquet data files); OPTIMIZE + VACUUM via Athena SQL; snapshot por commit. (Ch14)

**Apache Spark** — framework de processamento distribuído; substituto do MapReduce; suporta batch e streaming; base do AWS Glue ETL e Amazon EMR. (Ch07, Ch17)

**AppFlow** — serviço de ingestão gerenciada para SaaS (Salesforce, SAP, Marketo, Zendesk, Slack, etc.); transforma e carrega para S3, Redshift, ou outros destinos sem código. (Ch06)

**at-least-once delivery** — garantia de mensageria onde mensagem pode ser entregue mais de uma vez; idempotência do consumidor necessária para evitar duplicação; padrão do Kinesis Data Streams e SQS. (Ch06)

**AWS CDK** — Cloud Development Kit; escreve recursos AWS em Python/TypeScript/Java/Go/C#; converte para CloudFormation; 13 linhas Python → 500+ linhas CFN com secure defaults. (Ch16)

**AWS CloudFormation** — IaC em YAML ou JSON; Parameters para multi-env (dev/test/prod com mesmo template); integração com CodePipeline para deploy automático. (Ch16)

**AWS CodePipeline** — serviço de continuous delivery; detecta commit via CloudWatch Events → executa stages (Source → Build → Deploy); Pipeline de código (S3) e Pipeline de infra (CFN). (Ch16)

**AWS Database Migration Service (DMS)** — migração e replicação de bancos de dados relacionais; full load (carga inicial) e CDC (Change Data Capture) para replicação contínua. (Ch06)

**AWS Glue** — serviço serverless de ETL; Glue ETL (Apache Spark para transformações); Glue Crawler (descobre schema e registra no Glue Catalog); Glue Data Catalog (metastore técnico); DataBrew (transformação no-code). (Ch07)

**AWS Glue Data Catalog** — metastore centralizado (compatível com Hive metastore); armazena schema, localização e partições; base para Athena, Redshift Spectrum, EMR. (Ch04, Ch07)

**AWS Step Functions** — orquestrador serverless baseado em state machines; linguagem ASL (Amazon States Language); estados: Task, Choice, Parallel, Wait, Map, Pass, Succeed, Fail; integração nativa com 200+ serviços AWS. (Ch10)

**batch ingestion** — ingestão de dados em lotes periódicos (horária, diária, semanal); contrasta com streaming; ferramentas: DMS full load, AppFlow, DataSync, Glue ETL. (Ch06)

**bronze / silver / gold** — nomenclatura de zonas de dados alternativa a raw/curated/consume; bronze = dados brutos, silver = limpos e conformados, gold = agregados para consumo. (Ch02, Ch05)

**business glossary** — dicionário de termos padronizados de negócio no DataZone; evita variações (USA vs United States vs U.S.); vincula termos a datasets. (Ch15)

**CDC (Change Data Capture)** — técnica de replicação que captura apenas as mudanças (INSERT/UPDATE/DELETE) em vez de copiar a tabela inteira; DMS suporta CDC via log mining. (Ch06)

**CloudTrail** — log de todas as chamadas de API na conta AWS; auditoria de quem fez o quê e quando; essencial para compliance e investigação de incidentes. (Ch04)

**columnar storage** — formato de armazenamento onde dados são organizados por coluna, não por linha (ex.: Parquet, ORC); queries analíticas que filtram e agregam colunas específicas leem apenas os dados necessários. (Ch07)

**compaction (MOR)** — processo periódico em OTFs com Merge-on-Read que mescla delta log files no base Parquet file; necessário para restaurar performance de leitura; roda em horário off-peak. (Ch14)

**COW (Copy-on-Write)** — estratégia de write em OTFs: ao atualizar/deletar registro, reescreve o arquivo Parquet inteiro; leituras rápidas, escritas lentas; ideal para workloads read-heavy. (Ch14)

**data catalog** — inventário de datasets com metadata técnica (schema, localização, partições) e de negócio (descrição, owner, SLA, termos de glossário); previne data swamp. (Ch04)

**data consumer** — persona que consome dados do data lake/warehouse; tipos: business user (QuickSight), analyst (Athena, SQL), data scientist (SageMaker, notebooks), aplicação (DynamoDB, API). (Ch08)

**data engineering** — disciplina de construir e manter pipelines que coletam, transformam e disponibilizam dados para analytics e ML; distinto de data science (que analisa) e software engineering (que constrói sistemas transacionais). (Ch01)

**data lakehouse** — arquitetura que combina flexibilidade e custo do data lake (S3 + Parquet) com capacidades de data warehouse (ACID, schema enforcement, time travel, SQL); habilitado por OTFs. (Ch02, Ch14)

**data mesh** — abordagem organizacional (não técnica) criada por Zhamak Dehghani (2019); move responsabilidade de dados analíticos para domínios de negócio; 4 princípios: domain ownership, data as a product, self-service platform, federated governance. (Ch15)

**data product** — dataset analítico tratado como produto de software: com SLA, documentação, owner, qualidade garantida, descobrível e acessível; conceito central do data mesh. (Ch15)

**data product owner** — novo papel por domínio no data mesh; responsável por criar, manter e garantir qualidade dos data products; entende negócio do domínio e necessidades dos consumidores. (Ch15)

**data steward** — papel por domínio no data mesh; garante compliance com políticas do governance group central; pode criar políticas adicionais específicas do domínio. (Ch15)

**data swamp** — data lake sem catalog, sem qualidade, sem governança; dados sem metadata = dados inacessíveis; prevenido com Glue Catalog + DataZone + Lake Formation. (Ch02, Ch04)

**DataBrew** — ferramenta no-code da AWS para profiling e transformação visual de dados; 300+ transformações; integrada ao Glue Catalog; output para S3. (Ch07)

**DataOps** — metodologia que aplica DevOps ao engenharia de dados: IaC, SCM, CI/CD, testes automatizados, observability; torna pipelines reproduzíveis, auditáveis e sustentáveis. (Ch16)

**DataSync** — serviço AWS para ingestão de dados de armazenamento on-premises (NFS, SMB, HDFS) ou de outros clouds para S3; transferência acelerada. (Ch06)

**data warehouse** — banco de dados colunar otimizado para analytics; schema-on-write; SQL padrão; integração nativa com ferramentas de BI; ex.: Amazon Redshift. (Ch02, Ch09)

**Delta Lake** — Open Table Format criado pela Databricks (2016); Linux Foundation; somente Parquet; destaque: Z Ordering (query otimization), Shallow Clone (copy-sem-dados), Change Data Feed (log de mudanças); protocolo aberto → interoperabilidade. (Ch14)

**DPU (Data Processing Unit)** — unidade de compute do Glue; 1 DPU = 4 vCPUs + 16 GB RAM; Glue default = 10 DPUs; auto-scaling deve ser habilitado explicitamente. (Ch16, Ch17)

**ELT (Extract, Load, Transform)** — variante do ETL onde dados são carregados primeiro no destino e transformados lá; common em cloud DWs (Redshift, BigQuery, Snowflake). (Ch01)

**ETL (Extract, Transform, Load)** — paradigma clássico de pipeline: extrai da fonte, transforma, carrega no destino; contrastado com ELT em ambientes cloud-native. (Ch01)

**exactly-once delivery** — garantia de mensageria onde mensagem é processada exatamente uma vez; mais difícil de implementar que at-least-once; requer idempotência ou deduplicação. (Ch06)

**federated computational governance** — princípio #4 do data mesh: grupo de representantes de domínios + plataforma define padrões mínimos (nomenclatura, formatos, qualidade); enforcement via automação. (Ch15)

**FinOps** — função cross-funcional (eng + finance + negócio) para gestão de custos cloud; inclui educação de engenheiros sobre cost optimization, dashboards de spending, e decisões data-driven. (Ch17)

**Foundation Model (FM)** — modelo pré-treinado em grande volume de dados públicos; base para soluções especializadas; exemplos: Claude (Anthropic), GPT (OpenAI), Titan (Amazon), Stable Diffusion. (Ch13)

**full load** — carga completa de uma tabela; usado na migração inicial via DMS; contrasta com CDC (replicação incremental). (Ch06)

**Glue DynamicFrame** — abstração do Glue ETL sobre Spark DataFrame; suporta schema flexível (campos com múltiplos tipos); convertível para DataFrame via `.toDF()`. (Ch07)

**HyperLogLog (HLL)** — algoritmo probabilístico para COUNT DISTINCT aproximado; Athena suporta via `approx_count_distinct()`; 2–3% de erro, 100x mais rápido que COUNT DISTINCT exato. (Ch11)

**IaC (Infrastructure as Code)** — definição de recursos de infraestrutura em arquivos versionáveis; CloudFormation (YAML/JSON), Terraform (HCL), CDK (Python/TS/Java); base do DataOps. (Ch16)

**IAM (Identity and Access Management)** — serviço de controle de acesso AWS; usuários, grupos, roles e policies; base de segurança de toda a conta; Lake Formation estende IAM para permissões em nível de tabela/coluna/row. (Ch04)

**KMS (Key Management Service)** — serviço gerenciado de chaves de criptografia; integrado a S3, Redshift, Glue, Kinesis; criptografia em repouso. (Ch04)

**Lake Formation** — ver Amazon Lake Formation. (Ch04)

**Lambda** — serviço serverless de compute; funções Python/Node.js/Go; ideal para transformações leves, triggers de eventos S3, processamento de mensagens SQS; limit de 15 min de execução. (Ch03, Ch07)

**latency** — atraso entre produção e disponibilidade dos dados; batch = latência alta (minutos a dias); streaming = latência baixa (sub-segundo a segundos). (Ch01)

**LLM (Large Language Model)** — Foundation Model especializado em texto; arquitetura Transformer; casos de uso: summarization, Q&A, geração de código, tradução; base do QuickSight Generative BI e CodeWhisperer. (Ch13)

**manifest file (Iceberg)** — arquivo Avro com metadata de subset de data files: partition, record count, column min/max, null count; referenciado pelo manifest list. (Ch14)

**manifest list (Iceberg)** — arquivo Avro (`snap-*.avro`) que lista todos os manifest files de um snapshot; criada por snapshot; permite time travel sem listar arquivos S3. (Ch14)

**materialized view (Redshift)** — resultado de query armazenado fisicamente e atualizado incrementalmente; evita re-computação de aggregações caras. (Ch09)

**medallion architecture** — ver bronze/silver/gold. (Ch02, Ch05)

**metadata forms (DataZone)** — formulários por domínio com campos obrigatórios para publicação de datasets; campos: string, boolean, date, integer, decimal, linked a glossário. (Ch15)

**MOR (Merge-on-Read)** — estratégia de write em OTFs: ao atualizar/deletar, cria delta log (Avro); leitura faz merge em runtime; escritas rápidas, leituras mais lentas até compaction. (Ch14)

**MSK (Managed Streaming for Apache Kafka)** — Kafka gerenciado na AWS; para equipes que já usam Kafka ou precisam de compatibilidade com ecossistema Kafka (Kafka Connect, KSQL). (Ch06)

**mouthful (Netflix pattern)** — batch ótimo de arquivos passado a um job Spark; tamanho determinado por file size acumulado dos eventos SQS; resolve overhead fixo de inicialização do Spark. (Ch17)

**open table format (OTF)** — camada de metadata sobre Parquet/S3 que adiciona ACID, time travel, schema evolution e record-level updates; os 3 principais: Delta Lake, Apache Hudi, Apache Iceberg. (Ch14)

**OPTIMIZE (Iceberg/Athena)** — compação de data files: mescla small files em files maiores e delete files nos base files; melhora performance de leitura; executado via `OPTIMIZE db.table REWRITE DATA USING BIN_PACK`. (Ch14)

**orchestration** — coordenação da execução sequencial ou paralela de tarefas de pipeline; ferramentas: Step Functions (event-driven, state machines), MWAA/Airflow (DAG-based, schedule-driven), EventBridge (trigger por evento). (Ch10)

**Parquet** — formato colunar open-source; compressão por coluna (Snappy, GZIP); schema embutido; base dos data files em todos os OTFs; padrão para data lakes AWS. (Ch07)

**partition pruning** — otimização onde o query engine lê apenas as partições relevantes baseado nos predicados do WHERE; requer particionamento alinhado com os padrões de query. (Ch07)

**PII (Personally Identifiable Information)** — dados que identificam um indivíduo; ex.: nome, CPF, email, IP; requerem proteção especial; detectados por Amazon Macie; GDPR exige direito ao esquecimento (DELETE + VACUUM em OTFs). (Ch04)

**pipeline orchestration** — ver orchestration. (Ch10)

**SPICE (QuickSight)** — Super-fast Parallel In-memory Calculation Engine; armazenamento in-memory do QuickSight; queries em SPICE são mais rápidas e baratas que direct query no S3/Redshift. (Ch12)

**Redshift RA3** — tipo de nó Redshift com managed storage (compute escalável independente de storage); dados em S3 gerenciado (RMS); paga compute e storage separadamente. (Ch09)

**Redshift Spectrum** — extensão do Redshift para query S3; processa dados S3 sem carregar no cluster; cobrado por bytes escaneados; lê Hudi (COW), Delta Lake, e Iceberg (preview). (Ch09)

**SageMaker Autopilot** — AutoML: recebe dataset tabular + coluna target → treina e tuna múltiplos modelos → leaderboard → usuário deploya o melhor sem código. (Ch13)

**SDLF (Serverless Data Lake Framework)** — framework open-source da AWS Professional Services; implementado em Formula 1, Amazon Ireland, Naranja Finance; camadas: Foundation (S3, DynamoDB, ELK), Teams, Datasets, Pipelines (Stage A light + Stage B heavy via Step Functions), Transformations. (Ch16)

**SCM (Source Control Management)** — controle de versão de código; Git/CodeCommit; cada mudança = commit rastreável, revisável, revertível. (Ch16)

**schema evolution** — capacidade de alterar schema (ADD/DROP/RENAME/REORDER colunas, mudar tipo) sem quebrar queries existentes; suportado por todos os OTFs. (Ch14)

**self-service data infrastructure** — princípio #3 do data mesh: time central constrói plataforma (S3, Glue, LF, DataZone, CI/CD) que domínios usam para criar data products sem ticket para time central. (Ch15)

**snapshot (OTF)** — ponto no tempo de uma tabela OTF; criado por cada commit (INSERT/UPDATE/DELETE/OPTIMIZE); base do time travel; mantido até VACUUM deletar. (Ch14)

**sort key (Redshift)** — coluna(s) que determinam a ordem física dos dados no disco; compound sort key = prefixo de colunas; interleaved sort key = peso igual para todas as colunas; colunas de filtro frequente devem ser sort key. (Ch09)

**streaming ingestion** — ingestão contínua de dados em tempo real; ferramentas: Kinesis Data Streams (processamento), Kinesis Firehose (delivery), MSK (Kafka); latência sub-segundo a segundos. (Ch06)

**time travel** — query de tabela OTF em timestamp histórico; `FOR TIMESTAMP AS OF '...'`; retorna dados do snapshot pré-especificado; dados acessíveis até VACUUM apagar snapshots antigos. (Ch14)

**VACUUM (Iceberg/Athena)** — deleta snapshots antigos e arquivos associados; `vacuum_max_snapshot_age_seconds` (padrão 5 dias); obrigatório para GDPR right to be forgotten. (Ch14)

**VPC Flow Logs** — logs de tráfego de rede entre interfaces de rede em uma VPC; captura IP de origem/destino, porta, protocolo, bytes; entregues a S3 ou CloudWatch Logs. (Ch17)

**workgroup (Athena)** — agrupamento de usuários e queries com controles de custo, acesso e configuração; limita bytes escaneados por query ou por workgroup; isola ambientes dev/prod. (Ch11)

**Z Ordering (Delta Lake)** — reorganiza data files para co-localizar valores similares de múltiplas colunas; otimiza queries com filtros em 2–3 colunas frequentes; reescreve todos os Parquet files do subset. (Ch14)

# Chapter 3: The AWS Data Engineer's Toolkit

## Core Idea
AWS oferece mais de 200 serviços; para data engineering, o desafio não é aprender cada serviço, mas saber qual serviço escolher para cada cenário — este capítulo mapeia as quatro categorias de serviços (ingestão, transformação, orquestração, consumo) com regras de decisão claras.

## Frameworks Introduced

- **Four-Category Toolkit Model**
  - Ingestion → Transformation → Orchestration → Consumption
  - Cada pipeline atravessa essas quatro camadas; ferramentas diferentes para cada camada
  - O engenheiro escolhe a melhor ferramenta por camada com base no tipo de dado, volume e requisitos de latência

- **When-to-Use Decision Framework** (por serviço — ver Reference Tables)

## Key Concepts

- **CDC (Change Data Capture)**: captura de mudanças no banco de dados via transaction logs; DMS adiciona coluna `Op` (I/U/D) nos arquivos S3 para rastrear inserts, updates e deletes
- **Kinesis Shard**: unidade de capacidade de streaming; Kinesis Data Streams oferece ~70ms de latência; Firehose buffer de 1–15min antes de escrever
- **DPU (Data Processing Unit)**: unidade de capacidade do AWS Glue; jobs são cobrados por DPU × tempo de execução
- **Glue Crawler**: processo que examina arquivos em S3, infere schema e popula o Glue Data Catalog automaticamente
- **Glue Data Catalog**: catálogo técnico compatível com Hive metastore; usado por Athena, EMR e Glue ETL como fonte de schema
- **Lambda Layer**: pacote zip com bibliotecas externas (ex.: AWS SDK for pandas) que pode ser reutilizado em múltiplas funções Lambda
- **Redshift Spectrum**: extensão do Redshift que permite queries em dados externos no S3 (via Glue Data Catalog) combinados com dados internos do warehouse
- **RMS (Redshift Managed Storage)**: dados do Redshift armazenados em S3; SSD local serve como cache de dados quentes — separado dos dados S3 acessíveis via Spectrum
- **MWAA (Managed Workflows for Apache Airflow)**: versão gerenciada do Airflow; não é serverless — cobra por environment size mesmo quando idle
- **Amazon States Language (ASL)**: JSON estruturado usado para definir state machines no Step Functions
- **Dynamic Partitioning (Kinesis Firehose)**: particionar dados no S3 com base em campos do payload durante ingestão streaming
- **AWS SDK for pandas (awswrangler)**: biblioteca Python open-source criada pela AWS para simplificar tarefas ETL comuns em ambiente AWS

## Reference Tables

### Serviços de Ingestão — Quando Usar

| Serviço | Use quando | Não use quando |
|---------|-----------|----------------|
| **Amazon DMS** | Migrar/replicar DB para S3 ou outro DB; CDC contínuo | Carga alta pode impactar DB de produção |
| **Kinesis Firehose** | Streaming → S3/Redshift/OpenSearch com buffer (1–15min) | Latência <1min necessária; destino não suportado |
| **Kinesis Data Streams** | Processamento real-time, latência ~70ms; aplicação customizada | Use Firehose se destino suportado e latência >1min OK |
| **Kinesis Data Analytics** | Análise streaming com Apache Flink; métricas em janela de tempo | |
| **Amazon MSK** | Migrar Kafka existente para cloud; ecossistema Kafka open-source importante | Criando do zero sem dependência Kafka → prefira Kinesis |
| **Amazon AppFlow** | Fonte é SaaS suportada (Salesforce, Google Analytics, SAP) | Transformações complexas necessárias; fonte não suportada |
| **AWS Transfer Family** | Receber arquivos via FTP/SFTP/FTPS/AS2 de parceiros | |
| **AWS DataSync** | Sincronizar de NFS/SMB/HDFS/Azure/GCS para S3 | Datasets muito grandes onde rede não é prática → Snow |
| **AWS Snow Family** | Volume enorme sem boa conectividade de rede | Verifique se DataSync não é mais rápido para o volume |
| **AWS Glue (ingestão)** | Fonte tem conector Glue disponível; ingestão + transformação juntas | Só ingestão sem transformação → use serviço dedicado |

### Serviços de Transformação — Quando Usar

| Serviço | Use quando | Limite |
|---------|-----------|--------|
| **AWS Lambda** | Transformações leves; triggers por evento (S3, Kinesis) | Max 15min execução, 10GB memória; sem estado |
| **AWS Glue ETL (Spark)** | Datasets grandes; código Spark existente; conectores do marketplace | Custo maior vs EMR para jobs longos |
| **AWS Glue DataBrew** | Analistas/cientistas sem código; 250+ transformações visuais; PII detection | Transformações muito complexas |
| **Amazon EMR** | Spark + ecossistema Hadoop completo (Hive, Presto, Hudi); custo mais baixo | Mais configuração; requer expertise |

### Serviços de Orquestração — Quando Usar

| Serviço | Use quando | Não use quando |
|---------|-----------|----------------|
| **Glue Workflows** | Pipeline usa apenas Glue (crawlers + ETL jobs) | Precisa integrar Lambda ou outros serviços |
| **AWS Step Functions** | Pipeline multi-serviço; 220+ integrações nativas; serverless | Time já usa Airflow com Python DAGs |
| **MWAA (Airflow)** | Migrar Airflow existente; time já tem skills Airflow | Novo projeto sem Airflow — Step Functions é mais simples e serverless |

### Serviços de Consumo — Quando Usar

| Serviço | Caso de uso | Notas |
|---------|-------------|-------|
| **Amazon Athena** | SQL ad-hoc sobre S3; serverless; sem setup | Federated Query permite joins com DynamoDB, RDS, CloudWatch Logs |
| **Redshift** | BI com alta concorrência e baixa latência; queries complexas em dados altamente estruturados | Storage mais caro; carregar apenas dados "quentes" |
| **Redshift Spectrum** | Queries históricas no S3 combinadas com dados recentes no warehouse | Dados S3 acessíveis a todas as ferramentas; RMS só acessível pelo Redshift |
| **Amazon QuickSight** | Visualizações interativas para usuários de negócio; drill-down e filtros | Serverless; preço por author/reader |

### Snow Family Comparison

| Device | Peso | Storage | Compute | GPU |
|--------|------|---------|---------|-----|
| Snowcone | 2.1 kg | 8–14 TB | 2 vCPUs, 4GB RAM | Não |
| Snowball Edge Compute | 22.5 kg | 28 TB SSD | 104 vCPUs, 416GB RAM | Opcional (Tesla V100) |
| Snowball Edge Storage | 22.5 kg | 210 TB SSD | 104 vCPUs, 416GB RAM | Não |

## Worked Example

**Lambda CSV → Parquet com trigger S3** (exercício central do capítulo):

```python
import boto3
import awswrangler as wr
from urllib.parse import unquote_plus

def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])
        
        # Inferir DB e table name do path: dms/sakila/film/LOAD01.csv
        key_list = key.split("/")
        db_name = key_list[len(key_list)-3]      # ex: "sakila"
        table_name = key_list[len(key_list)-2]   # ex: "film"
        
        input_path = f"s3://{bucket}/{key}"
        output_path = f"s3://dataeng-clean-zone-INITIALS/{db_name}/{table_name}"
        
        # Ler CSV em DataFrame
        input_df = wr.s3.read_csv([input_path])
        
        # Criar database no Glue se não existir
        current_databases = wr.catalog.databases()
        if db_name not in current_databases.values:
            wr.catalog.create_database(db_name)
        
        # Escrever Parquet + registrar no Glue Data Catalog
        result = wr.s3.to_parquet(
            df=input_df,
            path=output_path,
            dataset=True,
            database=db_name,
            table=table_name,
            mode="append"
        )
        return result
```

**Setup**: Lambda Layer com `awswrangler` → IAM Role com S3 (leitura landing, escrita clean) + CloudWatch + Glue:* → Trigger: S3 ObjectCreate com suffix `.csv` → Timeout: 1 minuto (default 3s é insuficiente).

**CDC com DMS** — arquivo gerado para sequência de operações em `custid=9335`:
```
I, 9335, Smith, John, "1 Skyline Drive, NY, NY", 201-555-9012  ← INSERT
U, 9335, Smith, John, "1 Skyline Drive, NY, NY", 201-555-9034  ← UPDATE (phone)
D, 9335, Smith, John, "1 Skyline Drive, NY, NY", 201-555-9034  ← DELETE
```

## Key Takeaways

1. Regra de ouro de ingestão: use o serviço mais específico para a fonte (DMS para DB, Firehose para streaming simples, AppFlow para SaaS, DataSync para on-prem) — Glue apenas quando não existe serviço dedicado
2. Lambda para triggers e transformações leves; Glue ETL/EMR para volume; DataBrew para analistas sem código
3. Step Functions é a escolha padrão para orquestração multi-serviço — serverless, 220+ integrações; MWAA apenas se já existe investimento em Airflow
4. Athena = consulta ad-hoc sem setup; Redshift = BI produção com alta concorrência; Redshift Spectrum = ponte entre os dois
5. MWAA não é serverless — cobra mesmo quando idle; Step Functions usa modelo de consumo
6. Glue Data Catalog é o hub central: Athena, EMR, Glue ETL, Redshift Spectrum — todos o usam como fonte de schema

## Connects To

- **Ch04**: Data Governance — IAM policies e Glue Data Catalog em contexto de segurança
- **Ch06**: Ingestão em profundidade — DMS, Kinesis, AppFlow hands-on
- **Ch07**: Transformação em profundidade — Glue ETL, EMR hands-on
- **Ch09**: Amazon Redshift deep dive — MPP, Spectrum, data marts
- **Ch10**: Orquestração — Step Functions hands-on completo
- **Ch11**: Amazon Athena deep dive — Federated Query, Athena for Spark
- **Ch12**: QuickSight hands-on — visualizações

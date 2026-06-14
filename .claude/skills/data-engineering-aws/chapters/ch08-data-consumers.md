# Chapter 8: Identifying and Enabling Data Consumers

## Core Idea
Data engineer's job não termina na ingestão e transformação — termina quando o dado certo chega à ferramenta certa, para a pessoa certa, no tempo certo. Cada tipo de consumidor tem requisitos distintos; o data engineer deve entender esses requisitos para escolher toolset e formato de output corretos.

## Frameworks Introduced

- **Consumer-Driven Pipeline Design**
  - Quatro tipos de consumidores: Business Users (dashboards BI), Data Analysts (SQL ad hoc + limpeza), Data Scientists (ML, dados raw granulares), Business Applications (APIs, feeds, event-driven)
  - Cada tipo exige ferramentas, formatos e latências diferentes → definir consumer antes de escolher qualquer tech stack
  - Quando usar: início de qualquer projeto (Ch05 whiteboard) e ao formalizar pipeline ad hoc que analyst criou

- **Data Gravity Principle** (Dave McCrory)
  - Dados têm "massa": quanto maior o volume, maior a atração de consumers e aplicações
  - Consequência: mover datasets grandes para fora do lake fica progressivamente mais caro/difícil — design deve antecipar gravity e deixar dados onde consumers estão, não o contrário
  - Quando aplicar: ao decidir replicar dados para fora do lake vs. federated query no lugar

- **Self-Serve Data Platform Model** (Data Mesh)
  - Catálogo de negócio: discovery + metadata de contexto (origem, owner, glossário de negócio)
  - Mecanismo de acesso: consumer solicita → roteamento automático para aprovador → acesso provisionado sem cópia física
  - Quando usar: organização com muitos datasets e muitos consumers; evita que consumer precise pedir ao data engineer para cada acesso
  - Detalhe em Ch15

## Key Concepts

- **Data Democratization**: acesso amplo a dados para audiência crescente, em tempo e custo eficientes; expectativa padrão nos negócios atuais; pressiona data engineers a automatizar acesso em vez de ser gatekeeper
- **Amazon QuickSight**: BI serverless; dashboards interativos, relatórios multi-page, drill-down/filtros; conecta a S3, Redshift, MySQL, Oracle, Salesforce, ServiceNow, Jira; pago por author/reader; acesso mobile + portal + email agendado + embedded em apps
- **QuickSight Q (NLP)**: perguntas em linguagem natural → QuickSight identifica datasource relevante e gera visual automaticamente; ex.: "show me sales this month by segment"
- **Amazon Athena para analistas**: SQL ad hoc serverless; Federated Query (join S3 + Redshift + DynamoDB em query única); notebook integrado para Spark; pago por TB scanned
- **AWS Glue DataBrew**: visual data preparation para analistas, sem código; 250+ transforms built-in; conecta a S3, Redshift, Snowflake, JDBC, Glue/Lake Formation, Data Exchange, AppFlow; recipes (lista de steps) podem ser re-executadas como jobs agendados; custo: $1/30min de sessão interativa
- **Glue Studio vs DataBrew**: Studio gera código Spark editável (data engineers); DataBrew não gera código editável, mas tem 250+ transforms específicos para limpeza (data analysts); DataBrew recipes podem ser chamadas dentro de Glue Studio jobs
- **AWS Glue Python Shell**: Python serverless sem limite de runtime (vs Lambda: max 15min); para scripts Python que precisam rodar longos processos
- **AWS Glue for Ray**: processa large Python datasets em multi-node cluster; alternativa ao PySpark para times Python-first sem Scala/Java; usa framework open-source ray.io
- **RStudio on AWS**: EC2 (single node) ou EMR (multi-node para datasets grandes); R estatístico para analistas com skills de R
- **Amazon SageMaker Ground Truth**: labeling gerenciado para datasets ML; ML automático para casos de alta confiança; roteia casos difíceis para humanos (equipe própria ou Amazon Mechanical Turk com 500k+ contractors)
- **SageMaker Data Wrangler**: preparação visual de dados para ML (300+ transforms + PySpark + pandas); data scientists gastam até 70% do tempo em data prep — Wrangler reduz isso; exporta flow como Jupyter notebook ou código Python; fontes: S3, Athena, Redshift, Snowflake
- **SageMaker Clarify**: detecção de bias em datasets antes de treinar modelo ML; integrado com Data Wrangler; especifica atributos sensíveis (gênero, idade) → algoritmos detectam sub-representação → relatório visual com métricas
- **DataBrew Recipe**: sequência de steps de transformação salvos e re-executáveis; pode incluir join, format, filter, aggregate, custom SQL; base de um DataBrew job
- **DataBrew Job**: execução não-interativa de um recipe em escala completa; escreve output para S3 (CSV, Parquet, etc.); não cobra por sessão interativa

## Reference Tables

### Consumidores e ferramentas AWS primárias

| Tipo de Consumer | Perfil | Ferramenta primária AWS | O que precisam do data engineer |
|-----------------|--------|------------------------|--------------------------------|
| Business User | Excel power users, executivos | Amazon QuickSight | Dataset no formato correto em Redshift ou S3; acesso configurado |
| Data Analyst | SQL + Python/R; domínio de negócio | Athena, Glue DataBrew, QuickSight | Dados limpos disponíveis; formalizar pipelines ad hoc criados por eles |
| Data Scientist | ML, modelos preditivos; alta demanda de dados raw | SageMaker (Ground Truth, Data Wrangler, Clarify) | Acesso a dados raw granulares; volumes históricos |
| Business Application | Sistemas, call centers, CRM | S3, DynamoDB, Athena API, Kinesis | Feeds de dados em formato e latência corretos |

### Glue Studio vs Glue DataBrew

| Aspecto | Glue Studio | Glue DataBrew |
|---------|-------------|---------------|
| Persona alvo | Data engineer | Data analyst |
| Gera código Spark | Sim (editável) | Não |
| Número de transforms | Limitado (joins, schema, filter) | 250+ (cleansing, format, PII, pivot…) |
| PII detection | Redact / hash | Redact / hash / encrypt / swap / scramble |
| Custo sessão | Pago por DPU/hora no job | $1/30min sessão interativa |
| Integração | Pode executar recipe DataBrew | Recipe exportável para Studio |

### SageMaker tools para data preparation

| Ferramenta | Função | Diferencial |
|-----------|--------|-------------|
| Ground Truth | Labeling de datasets para ML supervisionado | Hybrid: ML automático + humanos para casos difíceis; Mechanical Turk |
| Data Wrangler | Preparação visual de dados para ML | 300+ transforms + PySpark + pandas; exporta notebook/Python |
| Clarify | Detecção de bias em datasets de treino | Integrado com Data Wrangler; relatório visual por atributo sensível |

### Python no AWS — quando usar cada serviço

| Cenário | Serviço |
|---------|---------|
| Script Python < 15min, event-driven | AWS Lambda |
| Script Python longo, sem limite de runtime | AWS Glue Python Shell |
| Dataset grande, multi-node Python | AWS Glue for Ray (ray.io) |
| Ambiente Python/Jupyter flexível | EC2 (single node) |
| R + grandes datasets | EMR + RStudio |

## Worked Example

**Hands-on Ch08 — Glue DataBrew: mailing list para marketing (customer + address → CSV)**

**Papel**: data analyst criando mailing list dos ex-clientes da locadora para campanha de streaming.

**Setup — conectar datasets ao DataBrew**:
- Dataset 1: `customer-dataset` → Glue Catalog → sakila → tabela `customer`
- Dataset 2: `address-dataset` → Glue Catalog → sakila → tabela `address`

**Recipe criada no projeto `customer-mailing-list`**:

```
Step 1: Join multiple datasets
  Type: Left join
  Table A (customer) × Table B (address) ON address_id = address_id
  Colunas selecionadas:
    Table A: customer_id, first_name, last_name, email
    Table B: address, district, postal_code

Step 2: Change to capital case → first_name
Step 3: Change to capital case → last_name
Step 4: Change to lowercase → email
```

**Job `mailing-list-job`**:
- Input: projeto `customer-mailing-list`
- Output: `s3://dataeng-clean-zone-<initials>/mailing-list/`
- Format: CSV (sem compressão) — para uso direto pelo marketing
- IAM role: criada automaticamente pelo DataBrew com permissão de escrita no destino S3
- Execução: "Create and run job"

**Resultado**: arquivo CSV com colunas `customer_id, first_name, last_name, email, address, district, postal_code`; nomes em Capital Case, emails em lowercase.

**Observação prática**: MySQL normalizou endereços em 3 tabelas (address → city → country). Recipe simples não inclui city/country — para isso, seriam necessários dois joins adicionais. DataBrew suporta, mas adiciona steps à recipe.

## Key Takeaways

1. Consumidor define tudo: antes de escolher ferramenta de ingestão ou transformação, identificar quem consome, com qual tool, com qual latência — consumer first, tech second
2. Data gravity: dados atraem consumers; mover datasets grandes é caro; preferir federated query (Athena, Redshift Spectrum) a copiar dados para fora do lake
3. Data analyst frequentemente cria pipelines ad hoc — data engineer deve ser parceiro para formalizar esses pipelines em source control e deployment process
4. Glue DataBrew para analistas (250+ transforms, visual, sem código); Glue Studio para data engineers (Spark, código editável); ambos co-existem e se integram
5. Data scientists precisam de dados raw granulares em volume; SageMaker Data Wrangler reduz o "70% do tempo em data prep" com 300+ transforms + PySpark + exportação para código
6. SageMaker Clarify detecta bias antes de treinar modelo — critical para ML em atributos sensíveis (gênero, idade, renda)
7. Self-serve data platform (catálogo + aprovação automática de acesso) é o que escala acesso a dados sem criar dependência do data engineer como gatekeeper

## Connects To

- **Ch05**: Consumer types identificados no whiteboard do Projeto Bright Light são os mesmos categorizados aqui
- **Ch07**: Dados transformados (streaming_films) são consumidos pelos tools descritos aqui
- **Ch09**: Redshift como destino para business users via QuickSight — data mart para BI de alta concorrência
- **Ch11**: Athena deep dive — ad hoc queries para data analysts
- **Ch12**: QuickSight deep dive — dashboards para business users
- **Ch13**: SageMaker deep dive — ML pipeline além do data prep
- **Ch15**: Data Mesh + self-serve data platform — catálogo de negócio e acesso automatizado

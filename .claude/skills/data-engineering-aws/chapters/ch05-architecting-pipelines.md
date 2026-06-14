# Chapter 5: Architecting Data Engineering Pipelines

## Core Idea
Pipelines bem-sucedidas começam pelo fim: identificar consumidores e seus requisitos antes de pensar em fontes ou ferramentas. Projetos que começam ingerindo tudo que existe ("If you build it, they will come") falham; projetos com escopo limitado, patrocínio executivo e arquitetura whiteboard com stakeholders têm sucesso.

## Frameworks Introduced

- **Work-Backward Pipeline Design (5 etapas)**
  1. Identificar **consumidores de dados** e seus requisitos (ferramentas, frequência, formato)
  2. Identificar **fontes de dados** — internas e externas; owner, formato, frequência de ingestão, PII
  3. Identificar **transformações** necessárias para mover raw → analytics-ready
  4. Determinar se **data mart** é necessário (Redshift, RDS) para casos de alta concorrência/baixa latência
  5. Criar diagrama de arquitetura de alto nível e distribuir para aprovação dos stakeholders
  - Quando usar: início de qualquer projeto de data engineering; antes de escolher qualquer ferramenta
  - Anti-pattern: começar escolhendo ferramentas antes de entender os consumidores

- **Whiteboarding Session Model**
  - Half-day workshop com stakeholders: sponsor executivo, data consumers, owners de sistemas de origem, data engineer lead
  - Objetivo: alinhamento de alto nível, não decisão técnica final; capturar quem, o quê e com que frequência
  - Output: diagrama de arquitetura + notas associadas distribuídos para aprovação
  - Questões-chave por fase: ver Reference Tables

- **Data Lake Transformation Layers**
  - Landing/Raw Zone: dados ingeridos as-is sem transformação
  - Clean Zone: qualidade verificada, formato padronizado (Parquet), colunas renomeadas, PII tokenizado
  - Curated Zone: denormalizado, enriquecido com dados externos, particionado por campo de query frequente

## Key Concepts

- **Escopo limitado + framework escalável**: primeiro projeto deve ser alcançável (meses, não anos) mas construído dentro de arquitetura reutilizável para projetos futuros — não resolver tudo de uma vez
- **Patrocínio executivo**: projetos de analytics falham sem buy-in da liderança; o primeiro projeto bem-sucedido vira caso de uso interno que impulsiona projetos futuros
- **Data Consumer Types**: Business User (dashboards BI), Data Analyst (SQL ad-hoc), Data Scientist (SQL + ML tools), Business Applications (APIs/feeds para outros sistemas)
- **Ingestão por frequência**: streaming contínuo (clickstream logs, Kinesis Agent), horário/diário (CDC com DMS de bancos relacionais), sob demanda (arquivos de parceiros via Transfer Family)
- **File Format Optimization**: converter CSV/XML/JSON → Apache Parquet para analytics (menor I/O, melhor compressão, metadados de schema embutidos)
- **Data Standardization**: coluna `DOB`, `dateOfBirth`, `birth_date` na mesma pipeline = problema; definir nomes e formatos corporativos únicos no clean zone
- **Data Partitioning**: agrupar fisicamente no S3 pelo campo mais usado em queries (geralmente data); query por mês lê só prefix do mês, não o dataset inteiro
- **Data Denormalization**: no data lake, join prévio (flatten) de tabelas relacionais melhora performance de query — oposto da normalização OLTP
- **AWS Data Exchange**: marketplace de dados terceiros na AWS; fornecedores entregam dados diretamente no S3 em formato e frequência acordados (ex.: dados meteorológicos históricos e forecast por ZIP code)
- **Kinesis Agent**: agente instalável em servidores on-premises para capturar e stream log files para Kinesis Firehose sem modificação da aplicação

## Reference Tables

### Questões por fase do whiteboarding

| Fase | Perguntas-chave |
|------|----------------|
| **Consumidores** | Quem são? Quais ferramentas usam (SQL, BI, ML)? Latência necessária? Frequência de atualização? |
| **Fontes** | Onde o dado está (DB, S3, SaaS, streaming)? Quem é owner do sistema? Quem é owner do dado? Frequência de ingestão? PII presente? |
| **Transformações** | Existe padrão corporativo de nomes de colunas? Qual formato de saída (Parquet)? Campo de partição? Ferramentas de transformação (Spark/SQL)? |
| **Data Mart** | Quantos usuários acessam simultaneamente? Latência aceitável? Queries complexas com muitos joins? |

### Tipos de consumidores e ferramentas AWS

| Tipo | Ferramenta preferida | AWS service |
|------|---------------------|-------------|
| Business User | BI dashboards | Amazon QuickSight |
| Data Analyst | SQL ad-hoc | Amazon Athena, Redshift |
| Data Scientist | SQL + ML | Athena + SageMaker |
| Business Application | API/feed | Athena API, S3, DynamoDB |

### Transformações comuns por zona

| De → Para | Transformação | Ferramenta comum |
|-----------|--------------|-----------------|
| Landing → Clean | CSV→Parquet, PII tokenization, quality checks, nomes padronizados | Glue ETL, Lambda |
| Clean → Curated | Denormalização, enriquecimento (joins com externos), particionamento | Glue ETL, EMR |
| Curated → Data Mart | Load seletivo de dados "quentes" | COPY (Redshift), DMS |

## Worked Example

**Projeto Bright Light — GP Widgets Inc.** (exercício hands-on do capítulo):

**Consumidores identificados**:
- Marketing specialists → dashboards BI (heatmap, coupon redemptions, ad campaigns) atualizados hourly; equipe usa Tableau mas marketing não tem licenças → oportunidade para QuickSight
- Data analysts (Terry Winship) → SQL ad-hoc em customer/product/returns/sales + clickstream; preferem SQL; data warehouse on-prem experience
- Data scientists (James Dadd) → SQL + SparkML; precisam de weather + clickstream + sales para treinar modelo de previsão de vendas por clima

**Fontes identificadas**:

| Fonte | Sistema | Owner sistema | Owner dado | Frequência | Formato |
|-------|---------|--------------|-----------|-----------|---------|
| Customer/Product/Returns/Sales | MS SQL Server 2016 on-prem | Owen McClave (DB team) | Chris Taylor (VP Sales) | Diária | → Parquet via DMS |
| Web clickstream logs | Apache HTTP Server on-prem (4 servidores) | Natalie Rabinovich | Marketing (Ronna Parish) | Near real-time | Apache log format → JSON via Kinesis Agent → Firehose |
| Weather data | AWS Data Exchange (fornecedor externo) | AWS Data Exchange | Marketing (orçamento pendente) | Diária | CSV |

**Transformações planejadas**:
- DB data: DMS → landing (Parquet) → Glue quality checks + standardização → clean → denormalização + enriquecimento com weather → curated (particionado por yyyy/mm/dd)
- Clickstream: Kinesis Agent → Firehose → Lambda validation → Parquet → clean (particionado por yyyy/mm/dd/hh)
- Weather: CSV daily → landing → clean sem transformação maior

**Data mart**: Redshift para dados "quentes" consultados pelo BI — QuickSight conecta ao Redshift para dashboards de baixa latência.

**Constraint descoberta**: Owen (DB team) tem reservas sobre segurança da cloud → ação: Shilpa agenda reunião separada para detalhar DMS + revisão de segurança com equipe de security antes de mover dados de produção.

## Key Takeaways

1. Sempre trabalhar de trás para frente: consumidores → fontes → transformações → data mart; nunca começar pela ingestão
2. "If you build it, they will come" é anti-pattern fatal em analytics — escopo limitado + outcome específico primeiro
3. Whiteboarding é para alinhamento de alto nível, não decisão técnica final; deixar tooling para próximas sessões focadas
4. Identificar data owner (quem aprova uso do dado) é tão importante quanto identificar system owner (quem gerencia o sistema)
5. Constraint de velocidade define a ferramenta: near-real-time clickstream → Kinesis; diário de DB → DMS; sob demanda → DataSync/Transfer Family
6. Particionamento deve ser decidido com base nas queries esperadas — não em intuição; whiteboard captura hipótese, sessão posterior confirma

## Connects To

- **Ch02**: Data lake zones (landing/clean/curated) — aplicadas concretamente aqui
- **Ch03**: Toolkit de ingestão e transformação — DMS, Kinesis, Glue escolhidos na fase de whiteboard
- **Ch06**: Ingestão em profundidade — DMS e Kinesis do projeto Bright Light detalhados
- **Ch07**: Transformação em profundidade — Glue ETL para as transformações whiteboarded aqui
- **Ch09**: Data mart Redshift — loading dos dados curated para BI de baixa latência
- **Ch12**: QuickSight — dashboards do marketing conectados ao Redshift

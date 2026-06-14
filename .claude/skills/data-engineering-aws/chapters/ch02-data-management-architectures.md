# Chapter 2: Data Management Architectures for Analytics

## Core Idea
Arquiteturas modernas de analytics evoluíram de data warehouses relacionais para data lakes e data lakehouses — cada arquitetura resolve limitações da anterior; um engenheiro de dados precisa dominar as três para escolher (e combinar) a certa para cada caso de uso.

## Frameworks Introduced

- **Star Schema vs. Snowflake Schema**
  - Star: fato central + dimensões denormalizadas → menos joins, mais simples, porém com duplicação em dimensões grandes
  - Snowflake: dimensões normalizadas em hierarquias → reduz redundância e storage, mas adiciona complexidade de joins
  - Quando usar Star: equipes de negócio que priorizam simplicidade de queries e updates frequentes em dimensões pequenas
  - Quando usar Snowflake: dimensões grandes com muita duplicação; quando storage é crítico

- **Data Lake Zones (3-Zone Pattern)**
  - Landing/Raw Zone: dados ingeridos as-is, sem transformação; cópia permanente da fonte
  - Clean/Transform Zone: validado, limpo, convertido para Parquet, particionado; PII removido/mascarado
  - Curated/Enriched Zone: lógica de negócio aplicada; pronto para consumo; catalogado e otimizado
  - Quando usar: design de qualquer data lake — nunca sobrescrever o raw, sempre avançar por zonas

- **ETL vs. ELT Decision Framework**
  - ETL: transformar fora do warehouse antes de carregar (usa Spark/Glue) → para transformações complexas, dados não relacionais, ou quando fonte ≠ formato do warehouse
  - ELT: carregar raw no warehouse e transformar com SQL nativo → para dados estruturados, volume alto, quando MPP do warehouse pode ser aproveitado
  - Critérios de decisão: complexidade das transformações + skills da equipe (SQL vs. PySpark) + velocidade necessária

- **Five-Layer Data Lake Architecture**
  1. Storage Layer (S3 — object store ilimitado, baixo custo)
  2. Catalog Layer (técnico: AWS Glue Data Catalog; negócio: schema + owner + freshness)
  3. Ingestion Layer (DMS para DB, Kinesis Firehose para streaming, AppFlow para SaaS)
  4. Processing Layer (AWS Glue, Amazon EMR — transforma e move entre zonas)
  5. Consumption Layer (Athena para SQL, SageMaker para ML, QuickSight para BI)

## Key Concepts

- **OLTP (Online Transaction Processing)**: armazena/atualiza dados transacionais em alto volume; row-oriented; não adequado para analytics
- **OLAP (Online Analytical Processing)**: repositório central para relatórios sobre grandes volumes; columnar; foco do livro
- **EDW (Enterprise Data Warehouse)**: repositório central com dados integrados, curados, confiáveis e altamente estruturados de todos os domínios de negócio
- **Fact Table**: armazena métricas numéricas granulares de um domínio (ex.: preço, quantidade); tem muitas foreign keys para dimensões
- **Dimension Table**: armazena contexto das métricas (ex.: loja, produto, data); usada para "slice and dice"
- **Data Mart**: repositório focado em um único domínio de negócio (vendas, finanças); schema mais simples; pode ser top-down (do warehouse) ou bottom-up (direto dos sistemas transacionais)
- **MPP (Massively Parallel Processing)**: leader node distribui query para múltiplos compute nodes que executam em paralelo; base da performance do Redshift
- **Columnar Storage**: dados armazenados por coluna (não por linha) — queries analíticas leem só as colunas necessárias; melhor compressão (mesmo tipo de dado agrupado)
- **Apache Iceberg**: formato de tabela open-source criado na Netflix; suporte a ACID, time travel, schema evolution; crescendo rapidamente em adoção
- **Apache Hudi**: formato de tabela criado pela Uber; doado ao Apache; usado por Amazon Transportation, Walmart, Robinhood
- **Delta Lake**: formato de tabela criado pela Databricks; open-source (Linux Foundation) + versão comercial
- **Federated Queries**: queries que cruzam diferentes engines de storage (ex.: Redshift + S3 + PostgreSQL) sem precisar copiar dados
- **Technical Catalog**: mapeia arquivos físicos no S3 para tabelas lógicas com schema (ex.: AWS Glue Data Catalog)
- **Business Catalog**: metadata de negócio — owner, data de atualização, definições de colunas, descrição de propósito
- **RMS (Redshift Managed Storage)**: S3 como storage dos dados do Redshift RA3; local SSD como cache para dados quentes
- **Shared-Nothing Architecture**: cada compute node tem processadores, memória e storage independentes — sem contenção

## Mental Models

- **Zonas como pipeline de qualidade**: Use a metáfora da linha de produção — raw zone = matéria-prima; clean zone = produto semiacabado; curated zone = produto final pronto para venda. Nunca voltar atrás na linha; nunca sobrescrever a matéria-prima.
- **Star vs. Snowflake = velocidade de leitura vs. facilidade de escrita**: Star schema favorece queries (menos joins); Snowflake favorece atualizações (menos duplicação). Escolha baseado em qual operação é mais frequente.
- **ETL = transformar antes de entrar; ELT = entrar primeiro, transformar dentro**: Se a cozinha (warehouse) tem MPP poderoso, cozinhe dentro. Se o ingrediente precisa de preparo especial que a cozinha não faz (Spark, ML), prepare fora.
- **Lakehouse = não escolha entre os dois**: Data lake para todos os dados (baixo custo, qualquer formato); warehouse para os dados "quentes" (alta performance, SQL). Tabelas como Iceberg trazem transações ACID ao lake.

## Anti-patterns

- **Schema-on-write exclusivo no data lake**: Converter todos os dados para um schema fixo antes de carregar elimina a flexibilidade do lake — use schema-on-read para dados não estruturados/semi-estruturados
- **Single-zone data lake**: Sem zonas, qualquer transformação sobrescreve os dados originais — sem auditoria, sem replay, sem recovery
- **Access keys permanentes para AWS CLI**: Expor access key ID + secret key é risco crítico — preferir AWS CloudShell (usa credenciais da console, sem keys) ou IAM roles
- **Carregar tudo no warehouse**: Storage de data warehouse é caro; dados raramente consultados devem ficar no S3 (data lake), com federated queries para acesso quando necessário
- **"Lakehouse" como termo técnico preciso**: É marketing term — cada vendor tem definição própria; avaliar funcionalidades concretas (ACID, federated queries, time travel) em vez do rótulo

## Reference Tables

### Comparação de arquiteturas

| Critério | Data Warehouse | Data Lake | Data Lakehouse |
|----------|---------------|-----------|----------------|
| Formatos suportados | Estruturado | Todos | Todos |
| Custo de storage | Alto | Baixo | Baixo (S3) |
| Performance de query | Alta (MPP, SSD) | Média | Alta + Média |
| Suporte ACID | Nativo | Limitado | Com Iceberg/Hudi/Delta |
| Ferramentas | SQL | SQL, Spark, ML | SQL, Spark, ML |
| Schema | On-write | On-read | Ambos |

### Star vs. Snowflake Schema

| Critério | Star Schema | Snowflake Schema |
|----------|-------------|-----------------|
| Estrutura de dimensões | Denormalizado | Normalizado |
| Número de joins | Menos | Mais |
| Duplicação | Mais | Menos |
| Velocidade de leitura | Mais rápido | Mais lento |
| Velocidade de update | Mais lento | Mais rápido |
| Complexidade | Menor | Maior |

### ETL vs. ELT

| Critério | ETL | ELT |
|----------|-----|-----|
| Onde transforma | Fora do warehouse | Dentro do warehouse |
| Ferramentas | Spark, Glue, Informatica | SQL nativo do warehouse |
| Volume alto | Possível, mas mais lento | Melhor (aproveita MPP) |
| Transformações complexas | Melhor (Spark, Python) | Limitado ao SQL |
| Skills necessárias | PySpark, Scala | SQL |

## Worked Example

**Criando o data lake em S3 via AWS CLI (exercício do capítulo):**

```bash
# Acessar AWS CloudShell no console (sem precisar de access keys)

# Criar bucket inicial (nome deve ser globalmente único)
aws s3 mb s3://dataeng-landing-zone-gse23
aws s3 mb s3://dataeng-clean-zone-gse23
aws s3 mb s3://dataeng-curated-zone-gse23
```

Resultado esperado:
```
make_bucket: dataeng-landing-zone-gse23
make_bucket: dataeng-clean-zone-gse23
make_bucket: dataeng-curated-zone-gse23
```

*Por que 3 buckets separados?* Cada zona tem política de acesso, lifecycle rules e permissões diferentes. O landing zone pode ter retenção de 7 anos e acesso restrito; o curated zone pode ser compartilhado com consumidores.

## Key Takeaways

1. OLTP = transações (row-oriented); OLAP = analytics (columnar) — nunca usar um sistema OLTP direto para reports pesados
2. Star schema: preferir quando queries são prioridade; Snowflake: quando updates e storage são prioridade
3. Data lake zones (raw → clean → curated) garantem auditabilidade e replay — sempre preservar o raw
4. ETL quando transformações são complexas/não-SQL; ELT quando MPP do warehouse pode fazer o trabalho
5. Apache Iceberg emergindo como formato dominante para data lakehouse com ACID + time travel
6. Federated queries reduzem necessidade de copiar dados entre sistemas, mas têm custo de performance

## Connects To

- **Ch04**: Data Governance e Cataloging — aprofunda technical catalog (Glue) e business catalog
- **Ch06**: Ingestion Layer — DMS, Kinesis, AppFlow em detalhe
- **Ch07**: Processing Layer — AWS Glue e EMR para transformação entre zonas
- **Ch08**: Consumption Layer — ferramentas para diferentes tipos de consumidores
- **Ch09**: Amazon Redshift em profundidade — MPP, RA3, data marts
- **Ch14**: Transactional Data Lakes — Iceberg, Hudi, Delta Lake em detalhe

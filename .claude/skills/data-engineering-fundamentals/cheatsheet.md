# Cheatsheet — Fundamentos de Engenharia de Dados

Tabelas de decisão e regras de referência rápida.

---

## Ciclo de Vida — Diagnóstico Rápido

| Sintoma | Etapa com problema | Ação imediata |
|---------|-------------------|---------------|
| Dados chegam tarde ou nunca chegam | Ingestão | Verificar conectores, CDC, filas; monitorar latência |
| Dados chegam mas estão errados | Sistemas de origem ou Transformação | Auditar contrato de dados upstream; revisar lógica de transformação |
| Dados corretos, mas ninguém usa | Disponibilização | Entrevistar usuários; verificar produto de dados vs. caso de uso real |
| Dados corretos, mas relatórios divergem entre squads | Transformação / Camada semântica | Centralizar definições em dbt metrics ou LookML |
| Pipeline cai toda semana | Orquestração / Arquitetura | Migrar de cron para DAG; adicionar dead-letter queue; assincronia |
| Custo cloud explodindo | Armazenamento / Query | Lifecycle policies; otimizar SELECT *; revisar frequência de snapshot |

---

## Lote vs. Streaming — Decisão

| Critério | Escolha |
|----------|---------|
| Relatórios de negócio, dashboards diários | Lote |
| Treinamento de modelo ML (dados históricos) | Lote |
| Alertas em tempo real, detecção de fraude | Streaming |
| Recomendação personalizada em tempo real | Streaming |
| Análise incorporada (usuário externo, sub-segundo) | Streaming + OLAP em tempo real |
| Downstream não suporta fluxo contínuo | Lote por padrão |
| Não há caso de uso claro para baixa latência | Lote (regra padrão) |

---

## Escolha de Armazenamento

| Requisito | Escolha |
|-----------|---------|
| Transações OLTP, escrita individual rápida | Banco relacional (PostgreSQL, MySQL) + SSD |
| Analytics SQL estruturado, governança | Data Warehouse (Snowflake, BigQuery, Redshift) |
| Dados brutos + ML + não estruturado | Data Lake (S3 + Parquet) |
| ACID + flexibilidade de data lake | Data Lakehouse (Delta Lake, Hudi, Iceberg) |
| Cache de sessão, baixa latência (<1ms) | Redis / Memcached (RAM) |
| IoT, alto volume, baixa latência, 1 índice | Colunas amplas (Bigtable, DynamoDB) |
| Grafos, traversals de conectividade | Banco de grafos (Neo4j, Neptune) |
| Métricas de sensores, séries cronológicas | Séries temporais (InfluxDB, TimescaleDB) |
| Pesquisa de texto, análise de logs | Elasticsearch / Solr |
| Compliance, raramente acessado | S3 Glacier / arquivístico |

---

## Escolha de Formato de Serialização

| Contexto | Formato | Compressão |
|----------|---------|------------|
| Ingestão em Kafka (schema obrigatório) | Avro | — (schema registry) |
| Data lake, queries OLAP | Parquet | Snappy ou Zstandard |
| CDC com updates frequentes | Hudi | — (interno) |
| Time travel + schema evolution | Iceberg | — (interno) |
| Cross-system in-memory (Spark ↔ Python) | Apache Arrow | — |
| Interoperabilidade com sistemas legados | CSV | gzip (arquivístico) |
| APIs, ingestão inicial | JSON / JSONL | — |
| Armazenamento de texto comprimido | CSV / JSON | gzip, bzip2 |
| Queries ad-hoc rápidas (data lake) | Parquet | Snappy |
| Streaming, bancos colunares | Qualquer | Zstandard, LZ4 |

---

## Modelagem Analítica — Escolha

| Situação | Abordagem |
|----------|-----------|
| Iteração rápida, proximidade com negócio | Kimball (esquema estrela) |
| Fonte única de verdade corporativa, rigor | Inmon (top-down, 3NF) |
| Esquema instável, mudanças frequentes | Data Vault (hubs/links/satélites, insert-only) |
| Simplicidade máxima, desempenho colunar | Tabela ampla (desnormalizada) |
| Histórico de dimensões necessário | SCD Tipo 2 (EFF_Start/EFF_End) |
| Apenas estado atual necessário | SCD Tipo 1 (substituição) |

---

## CDC — Escolha de Abordagem

| Situação | Abordagem |
|----------|-----------|
| Precisão de estado atual, tabela pequena | Snapshot completo |
| Volume alto, frequência baixa de mudança | Incremental por `updated_at` |
| Histórico completo de transações necessário | CDC log-based (WAL/Debezium) |
| Auditoria financeira, contabilidade | CDC log-based (nunca `updated_at`) |
| Réplica de leitura para analytics | Replicação síncrona |

---

## Build vs. Buy — Regra Rápida

| Decisão | Critério |
|---------|----------|
| Usar OSS comunitário | Tarefa comum, sem vantagem competitiva, comunidade ativa |
| Usar COSS gerenciado | OSS existe mas overhead ops é alto; custo de gerenciamento > licença |
| Usar SaaS proprietário | Nenhum OSS/COSS adequado; integração nativa com stack |
| Build interno | Gera vantagem competitiva real E não existe no mercado |
| **Nunca build** | Conectores de dados, autenticação básica, monitoramento padrão |

---

## Segurança — Checklist Mínimo

| Área | Verificação |
|------|------------|
| Credenciais | SSO + MFA ativo; sem senha hardcoded no código; gerenciador de senhas |
| Acesso | Privilégio mínimo; contas de serviço com escopo mínimo; revisão mensal |
| Dados | Criptografia em repouso (buckets, bancos, discos); HTTPS obrigatório |
| Rede | SSH sem 0.0.0.0/0; bancos atrás de VPC; whitelist de IPs |
| Monitoramento | Logs de acesso; alertas de faturamento; relatório de permissões não usadas |
| Backup | Backup testado com restauração (não apenas gravado) |
| Coleta | Não coletar dados sensíveis sem necessidade downstream real |

---

## Disponibilização — Tipo de Análise

| Usuário / Caso de uso | Tipo | Arquitetura |
|----------------------|------|-------------|
| Executivo, insights históricos | Análise de negócios | DW + BI (Looker, Tableau) |
| Operador, ação imediata | Análise operacional | OLAP em tempo real + alertas |
| Usuário da aplicação (SaaS) | Análise incorporada | OLAP alta concorrência (Druid, ClickHouse) |
| Cientista de dados, treinamento ML | Exploração + ML | Data lake + notebook + feature store |
| Vendedor no CRM, lead score | ETL Reverso | Hightouch/Census com guardrails |

---

## Anti-patterns Rápidos

| Anti-pattern | Consequência | Solução |
|--------------|-------------|---------|
| `SELECT *` em DW cloud | Custo por bytes lidos; scan completo | Selecionar colunas explicitamente |
| Admin para todos | Blast radius máximo em comprometimento | Grupos IAM por papel; mínimo necessário |
| Credencial no código | Vaza para git, logs, backups | Gerenciador de credenciais; variável de ambiente |
| Snapshot em tabela de 100GB+ diário | Custo e latência altos | CDC incremental ou log-based |
| Upserts frequentes em Parquet | COW: reescreve coluna inteira | Usar Hudi para workloads CDC |
| CSV no meio do pipeline | Sem schema, erros silenciosos | Parquet ou Avro com schema registry |
| Cron job como orquestrador | Sem dependências, falhas silenciosas | DAG (Airflow, Dagster, Prefect) |
| Bucket S3 público com dados sensíveis | Maior causa de vazamento cloud | Bucket privado + controle de acesso granular |
| ETL reverso sem guardrail | Loop de feedback sem controle | Limite de registros + threshold de anomalia |
| Modelar no nível agregado | Perde granularidade irreversivelmente | Sempre modelar no nível mais atômico |
| Backup sem teste de restauração | Falso senso de segurança | Testar restauração periodicamente |

---

## Maturidade de Dados — Diagnóstico

| Sintoma | Estágio | Prioridade |
|---------|---------|-----------|
| Dados improvisados, sem arquitetura | 1 — Começando | Base sólida antes de ML |
| Pipelines existem mas não escalam; DS limpa dados | 2 — Escalando | DataOps; suporte a ML |
| Cultura de dados estabelecida; novos dados não fluem | 3 — Liderando | Catálogo; linhagem; automação |

---

## Regras de Ouro

1. **Lote por padrão; streaming só com caso de uso claro.** [ch02]
2. **Arquitetura primeiro, tecnologia depois.** [ch04]
3. **Modelar no nível mais granular possível; agregar é trivial, desagregar é impossível.** [ch08]
4. **Contrato de dados antes do pipeline.** [ch05]
5. **Dado não coletado não pode vazar.** [ch07] [ch10]
6. **Lifecycle policies são obrigatórias (60–80% de economia).** [ch06]
7. **Nunca hardcode credenciais.** [ch07] [ch10]
8. **Confiança nos dados é fácil perder e difícil reconquistar.** [ch09]
9. **Build apenas quando gera vantagem competitiva real.** [ch04]
10. **Comece pelo caso de uso e usuário, não pela ferramenta.** [ch09]

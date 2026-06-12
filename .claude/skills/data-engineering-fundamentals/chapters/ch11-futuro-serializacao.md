# Ch11 — O Futuro da Engenharia de Dados + Serialização e Compressão

## Core Idea

O ciclo de vida da engenharia de dados veio para ficar — mas as ferramentas e papéis vão evoluir drasticamente. A Modern Data Stack (MDS) baseada em batch está dando lugar a uma pilha de dados em tempo real onde aplicações, ML e dados se fundem. Paralelamente, a escolha correta de formatos de serialização e compressão continua sendo uma alavanca subestimada de desempenho.

---

## Frameworks Introduzidos

### 1. Trajetória da Evolução da Pilha de Dados

```
Hadoop/MapReduce    → Modern Data Stack (MDS)    → Real-Time Data Stack
(infraestrutura       (cloud DW + ELT + SaaS        (streaming + OLAP
 manual complexa)      connectors, ainda batch)       em tempo real)
```

### 2. Modelo STL — Sucessor do ELT em Tempo Real

```
ELT (MDS):    Extract → Load → Transform (no DW, em batch)
STL (futuro): Stream → Transform (em movimento) → Load (contínuo)
```

Transformação migra do banco de dados para o pipeline de streaming.

### 3. Espectro de Serialização por Padrão de Acesso

| Formato | Orientação | Ideal para | Limitação |
|---------|-----------|-----------|-----------|
| CSV | Linha | Interoperabilidade legada | Sem schema, lento, propenso a erros |
| JSON/JSONL | Linha/Documento | APIs, ingestão inicial | Performance inferior a colunares |
| Avro | Linha + schema binário | Hadoop, streaming (Kafka) | Menos suporte em ferramentas modernas |
| Parquet | Colunar | Data lake, queries OLAP | Atualizações custosas (COW) |
| ORC | Colunar | Hive, ecossistema Hadoop | Suporte reduzido fora do Hadoop |
| Apache Arrow | Colunar em memória | Processamento cross-linguagem | Especializado para in-memory |
| Hudi | Híbrido (linha + colunar) | CDC + DW analítico | Complexidade operacional |
| Iceberg | Tabela + snapshot | Data lakehouse + time travel | Overhead de metadados |

### 4. Trade-off Velocidade vs. Taxa de Compressão

| Algoritmo | Foco | Uso típico |
|-----------|------|-----------|
| gzip / bzip2 | Alta taxa de compressão | Arquivos texto (JSON, CSV) em armazenamento |
| Snappy | Velocidade (baixa CPU) | Parquet, data lakes, queries ad-hoc |
| Zstandard / LZ4 / LZFSE | Velocidade + eficiência | Bancos colunares, streaming |

---

## Key Concepts

**DE não vai desaparecer** — ferramentas simplificadas = DE sobe na cadeia de valor para tarefas de nível mais alto. Analogia: frameworks móveis não eliminaram dev mobile; permitiram apps mais sofisticados.

**Sistema operacional de dados em escala cloud** — serviços como BigQuery, Snowflake, Lambda são análogos a serviços de sistema operacional, mas distribuídos. Próxima fase: APIs padronizadas de dados + catálogos de metadados (successores do Hive Metastore).

**Interoperabilidade via Parquet + Avro** — esses formatos estão se tornando o padrão de troca entre sistemas; superam CSV (sem schema) e JSON bruto (performance baixa).

**Orquestração próxima geração** — Airflow domina hoje; Dagster e Prefect reescrevem do zero com maior consciência de dados, integração com lineage/catálogo, IaC nativo (infraestrutura se cria na primeira execução do pipeline).

**Real-Time OLAP databases** — Druid, ClickHouse, Rockset, Firebolt: ingestão rápida + queries sub-segundo em dados em movimento. Habilitadores principais da pilha em tempo real.

**Fusão aplicação + dados** — em breve "pilha de aplicação = pilha de dados". Aplicações incorporam automação em tempo real via streaming + ML. Por que ter um dashboard para decidir uma ação repetitiva quando pode ser automatizada?

**Modelagem de dados migrará para upstream** — técnicas Kimball/Inmon são orientadas a batch, inadequadas para streaming. Futuro: definições de dados (semântica, métricas, linhagem) definidas onde os dados são gerados na aplicação.

**Dados de matéria escura (planilhas)** — 700M-2B usuários de planilhas. São aplicações interativas de dados com análise programável. Próxima categoria: combina interatividade de planilha com backend OLAP em cloud.

**Parquet e COW** — armazenamento colunar não é otimizado para atualizações de linha única: requer descompactar coluna, alterar, recompactar. Para updates frequentes usar Hudi (com camada row-based para writes recentes) ou Iceberg (snapshots).

**Apache Arrow** — formato binário in-memory colunar compartilhado entre linguagens (C, Python, Java, Go, Rust...). Elimina overhead de serialização/desserialização entre sistemas. Dremio é data warehouse construído sobre Arrow.

**Iceberg time travel** — rastreia todos os snapshots de uma tabela ao longo do tempo. Permite consultar o estado da tabela em qualquer ponto histórico. Gerencia tabelas de petabytes com evolução de schema.

**Hudi para CDC** — padrão: CDC stream chega em formato orientado por linhas (writes rápidos); tabela principal mantida em colunar (reads rápidos). Processo periódico de repacking funde os dois.

---

## Mental Models

**"O lote será para dados em tempo real o que o dial-up é para internet."** — Ingestão batch no início do pipeline se tornará gargalo inaceitável. Streaming como padrão; batch como caso especial.

**"Análise substituída por automação."** — Se a resposta a "o quê e quando?" leva a uma ação repetitiva, automatize. Dashboards são para decisões não automatizáveis.

**"Formato de serialização = decisão de arquitetura, não detalhe."** — Migrar CSV → Parquet pode gerar 10-100x melhoria de performance. Escolher no início do pipeline, não depois.

**"Interoperabilidade > performance proprietária."** — Parquet em data lake polyglot bate Snowflake proprietário quando há múltiplas ferramentas lendo os mesmos dados.

**"Compressão sem perdas: redundância reduzida, dados exatos."** — Para análise, usar sempre lossless (gzip, Snappy, Zstandard). Lossless para áudio/vídeo apenas em pipelines de mídia.

---

## Anti-patterns

- **CSV no meio do pipeline** — sem schema, propenso a erros de delimitador/escape, lento. Usar Parquet ou Avro nas etapas intermediárias.
- **JSON bruto em data lake de longo prazo** — performático apenas para ingestão inicial; migrar para Parquet downstream.
- **Ignorar interoperabilidade ao escolher formato** — formato proprietário do DW prende a um vendor; Parquet permite migração.
- **Credenciais no código de ciência de dados** — (reforço do ch10) notebooks em produção herdam o problema.
- **Assumir que batch é suficiente para sempre** — aplicações de dados em tempo real exigem latência sub-segundo; arquitetar para streaming desde o início.
- **Modelagem de dados pensada só para batch** — Kimball/Inmon não se encaixa em schemas evolutivos de streaming.
- **Compressão com perdas em dados analíticos** — resultados imprecisos. Sempre lossless para análise.
- **Upserts frequentes em Parquet puro** — sem Hudi/Iceberg, cada update reescreve coluna inteira (COW). Usar tabela Hudi para workloads CDC.

---

## Worked Example

**Cenário:** Migrar pipeline batch (MDS) para tempo real para e-commerce com recomendações em tempo real.

**Stack MDS (atual):**
```
Postgres (OLTP) →[Fivetran batch]→ Snowflake →[dbt]→ Looker dashboard
                                                  ↓
                                           [Python notebook]
                                           modelo recomendação (offline)
```

**Stack em tempo real (futuro):**
```
Postgres (OLTP) →[CDC Debezium]→ Kafka
                                    ↓
                             [Flink/Spark Streaming]
                             STL: transform em movimento
                                    ↓
                    ┌───────────────┼──────────────────┐
                    ▼               ▼                   ▼
              [ClickHouse]    [Feature Store]    [Iceberg/Hudi]
          (analytics OLAP     (treino online)    (histórico)
           sub-segundo)
                    ↓               ↓
              [Dashboard       [Modelo ML
               operacional]     em tempo real]
                                    ↓
                           [Recomendação na
                            página do produto]
```

**Serialização no pipeline:**
- Ingestão CDC → Avro (schema registry no Kafka)
- Armazenamento histórico → Parquet com Snappy (Iceberg para time travel)
- Updates de CDC → Hudi (linha para writes, colunar para reads)
- Exportação cross-system → Apache Arrow (Spark ↔ Python sem overhead)

---

## Key Takeaways

1. DE não vai desaparecer — ferramentas simplificadas sobem o nível de abstração; DE foca em problemas de maior valor.
2. MDS (batch-first) → Real-Time Data Stack (streaming-first + OLAP em tempo real). STL substitui ELT.
3. Fusão aplicação + dados + ML: pipelines de streaming + loops de feedback curtos = aplicações inteligentes (TikTok, Uber, Google como benchmark).
4. Orquestração evolui: Dagster/Prefect adicionam IaC nativo, lineage, consciência de dados; infraestrutura sobe no first run.
5. Parquet = padrão de interoperabilidade para data lakes; Avro = padrão para streaming (Kafka). CSV apenas para legado.
6. Apache Arrow elimina overhead serialização/desserialização cross-linguagem; base para nova geração de ferramentas.
7. Hudi = CDC + analytics (row layer para writes + columnar para reads + repacking periódico).
8. Iceberg = time travel + schema evolution + petabyte-scale; padrão emergente do data lakehouse.
9. Compressão: gzip/bzip2 para armazenamento de texto; Snappy/Zstandard/LZ4 para performance em queries.
10. Planilhas são a "matéria escura" dos dados — próxima categoria: interatividade de planilha + backend OLAP.

---

## Connects To

- [ch02] Ciclo de vida DE — o ciclo persiste; tempo entre etapas diminui no real-time stack
- [ch03] Arquitetura — data lakehouse (Hudi, Iceberg), Lambda/Kappa, real-time OLAP
- [ch06] Armazenamento — serialização (Parquet, ORC, Arrow) e compressão (Snappy, gzip) são detalhados aqui
- [ch07] Ingestão — streaming substitui batch como padrão; CDC + Avro no Kafka
- [ch08] Transformações — STL substitui ELT; streaming DAGs; modelagem de dados migra para upstream
- [ch09] Disponibilização — análise operacional em tempo real; embedded analytics com OLAP sub-segundo

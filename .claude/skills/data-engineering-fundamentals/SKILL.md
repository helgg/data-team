# data-engineering-fundamentals

## Para que serve esta skill

Guia prático para engenheiros de dados e arquitetos que precisam tomar decisões sobre:
- Escolha de arquitetura (data warehouse, lakehouse, mesh, lambda, kappa)
- Ingestão (CDC, streaming, batch, conectores)
- Armazenamento (formatos, camadas, lifecycle)
- Transformação (modelagem, SQL, streaming)
- Disponibilização (BI, ML, ETL reverso, embedded analytics)
- Segurança e privacidade
- Escolha de tecnologias ao longo do ciclo de vida

---

## Framework Central

### Ciclo de Vida da Engenharia de Dados

```
Geração → Armazenamento → Ingestão → Transformação → Disponibilização
                 ↑                                           ↓
                 └──────────── ETL Reverso ─────────────────┘

Elementos subjacentes (transversais a todas as etapas):
  Segurança · Governança · DataOps · Arquitetura · Orquestração · Engenharia de Software
```

**Use este framework como lente diagnóstica**: mapear qualquer problema a uma etapa; verificar elementos subjacentes cobertos.

---

## Princípios-Chave

| Princípio | Regra prática |
|-----------|---------------|
| Arquitetura vs. Ferramentas | Arquitetura é estratégia; tecnologia é tática. Nunca ao contrário. |
| Lote vs. Streaming | Lote por padrão; streaming só com caso de uso que justifica custo. |
| Build vs. Buy | Build apenas quando gera vantagem competitiva real. |
| Imutável vs. Transitório | Construir sobre imutáveis (S3, SQL, bash); camadas superiores = revisáveis. |
| Decisões reversíveis | Preferir portas de mão dupla; deliberar profundamente apenas em tipo 1. |
| Granularidade | Modelar no menor nível possível; agregar é trivial, desagregar impossível. |
| Confiança nos dados | Construída lentamente, destruída instantaneamente. Validação contínua. |
| Segurança ativa | Pessoas → Processos → Tecnologia. Pensamento negativo como ferramenta. |
| Evolução da pilha | MDS batch-first → Real-Time Stack (STL + OLAP em tempo real). |

---

## Índice de Tópicos

### Arquitetura e Tecnologia
- Princípios de boa arquitetura, RTO/RPO, acoplamento → **[ch03]**
- Data warehouse, data lake, lakehouse, Data Mesh, Lambda, Kappa → **[ch03]**
- TCO/TOCO, Build vs. Buy, Efeito Lindy, Serverless, Capex/Opex → **[ch04]**
- Maturidade de dados (estágios 1/2/3), Tipo A/B → **[ch01]**

### Ciclo de Vida — Etapas
- Ciclo de vida detalhado, temperatura dos dados, lote vs. streaming → **[ch02]**
- Sistemas de origem: OLTP, NoSQL, APIs, CDC, contratos de dados → **[ch05]**
- Armazenamento: hierarquia de cache, object storage, lakehouse, lifecycle → **[ch06]**
- Ingestão: CDC, snapshot, incremental, conectores, payload, dead-letter → **[ch07]**
- Transformação: SQL, modelagem (Kimball/Inmon/Vault), SCD, streaming → **[ch08]**
- Disponibilização: BI, ML, ETL reverso, camada semântica, confiança → **[ch09]**

### Elementos Subjacentes
- DataOps: automação, observabilidade, resposta a incidentes → **[ch02]**
- Governança: metadados, MDM, linhagem, GDPR → **[ch02]**
- Orquestração: DAG, Airflow, Dagster, Prefect, IaC → **[ch02]** **[ch11]**
- Segurança: Pessoas→Processos→Tecnologia, IAM, criptografia, monitoramento → **[ch10]**

### Formatos e Futuro
- Serialização: CSV, JSON, Avro, Parquet, ORC, Arrow, Hudi, Iceberg → **[ch11]**
- Compressão: gzip, bzip2, Snappy, Zstandard, LZ4 → **[ch11]**
- Real-Time Stack, STL, OLAP em tempo real (Druid, ClickHouse) → **[ch11]**
- Fusão aplicação + dados + ML; planilhas como "matéria escura" → **[ch11]**

---

## Arquivos de Referência Rápida

| Arquivo | Conteúdo |
|---------|----------|
| `cheatsheet.md` | Tabelas de decisão: lote vs. streaming, formatos, modelagem, CDC, segurança |
| `patterns.md` | Padrões técnicos detalhados: Data Lakehouse, CDC, ETL Reverso, Serialização |
| `glossary.md` | 80+ termos com definição e referência de capítulo |

---

## Índice de Capítulos

| Capítulo | Arquivo | Tópicos principais |
|----------|---------|-------------------|
| Ch01 | `chapters/ch01-descricao-engenharia-dados.md` | Definição de DE, ciclo de vida, maturidade de dados, Tipo A/B |
| Ch02 | `chapters/ch02-ciclo-de-vida-engenharia-dados.md` | Ciclo detalhado, temperatura, lote vs. stream, DataOps, governança |
| Ch03 | `chapters/ch03-arquitetura-dados.md` | 9 princípios, DW/lake/lakehouse/mesh, Lambda/Kappa, FinOps |
| Ch04 | `chapters/ch04-escolha-tecnologias.md` | TCO/TOCO, build vs. buy, Efeito Lindy, serverless, benchmarks |
| Ch05 | `chapters/ch05-sistemas-de-origem.md` | OLTP, NoSQL, APIs, CDC, contratos de dados, ACID vs. eventual |
| Ch06 | `chapters/ch06-armazenamento.md` | Cache hierarchy, object storage, separação compute/storage, lifecycle |
| Ch07 | `chapters/ch07-ingestao.md` | 8 fatores de ingestão, CDC, conectores, dead-letter, segurança |
| Ch08 | `chapters/ch08-consultas-modelagem-transformacao.md` | SQL, Kimball/Inmon/Vault, SCD, streaming, camada semântica |
| Ch09 | `chapters/ch09-disponibilizacao.md` | BI, ML, ETL reverso, SLA/SLO, confiança, LookML, dbt |
| Ch10 | `chapters/ch10-seguranca-privacidade.md` | Pessoas→Processos→Tecnologia, IAM, criptografia, monitoramento |
| Ch11 | `chapters/ch11-futuro-serializacao.md` | Real-Time Stack, STL, Parquet/Arrow/Hudi/Iceberg, compressão |

---

## Perguntas Frequentes → Capítulo

| Pergunta | Ver |
|----------|-----|
| Como escolher entre DW, data lake e lakehouse? | [ch03] [ch06] + cheatsheet |
| Quando usar streaming em vez de lote? | [ch02] + cheatsheet |
| Como fazer CDC de banco relacional? | [ch05] [ch07] + patterns |
| Como modelar dimensões com histórico? | [ch08] + patterns (SCD Tipo 2) |
| Como centralizar definições de métricas? | [ch08] [ch09] + patterns (camada semântica) |
| Como estruturar segurança para time de dados? | [ch10] + cheatsheet |
| Qual formato de serialização usar em cada estágio? | [ch11] + cheatsheet |
| Como migrar de batch para real-time? | [ch11] + patterns (Real-Time Stack) |
| Como avaliar se devo construir ou comprar uma ferramenta? | [ch04] + cheatsheet |
| Como configurar ETL reverso com segurança? | [ch09] + patterns |

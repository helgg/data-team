# Capítulo 6: Armazenamento

## Core Idea
Armazenamento ocorre em todas as etapas do ciclo de vida da engenharia de dados — não é uma etapa isolada, mas um substrato onipresente. A escolha correta exige entender três camadas em ordem crescente de abstração: **componentes físicos** (hardware), **sistemas de armazenamento** (como os dados são organizados e acessados) e **abstrações** (data warehouse, data lake, lakehouse). Conhecer a camada abaixo sempre informa as compensações da camada acima.

## Frameworks Introduzidos

- **Hierarquia de Cache — 6 Camadas**:

| Tipo | Latência | Largura de banda | Custo |
|---|---|---|---|
| Cache da CPU | 1 ns | 1 TB/s | N/D |
| RAM (DDR5) | 0,1 μs | 100 GB/s | ~$10/GB |
| SSD | 0,1 ms | 4 GB/s | ~$0,20/GB |
| HDD | 4 ms | 300 MB/s | ~$0,03/GB |
| Object storage | 100 ms | 10 GB/s (paralelo) | ~$0,02/GB/mês |
| Armazenamento arquivístico | 12 horas | Igual ao object storage | ~$0,004/GB/mês |

  - Usar: como mapa de decisão para cada camada do pipeline — onde os dados ficam e a que custo
  - Regra: armazenamento arquivístico = "cache reverso" — barato para guardar, caro para recuperar

- **ACID vs BASE**:
  - **ACID**: Atomicidade, Consistência, Isolamento, Durabilidade — padrão transacional, consistência forte
  - **BASE**: **B**asically Available (disponível com best-effort), **S**oft-state (estado incerto), **E**ventual consistency — padrão distribuído escalável
  - Regra: ACID = confiabilidade garantida, menor escala; BASE = escala horizontal, tolerância a staleness; saber qual modelo o sistema usa antes de construir o pipeline

- **Dados Quentes / Mornos / Frios**:
  - **Quente**: acesso frequente/instantâneo; SSD ou RAM; alto custo de armazenamento, baixo custo de recuperação
  - **Morno**: acesso ~mensal; object storage infrequent access (S3 IA, GCS Nearline); custo médio
  - **Frio**: raramente acessado; HDD, tape, Glacier; custo de armazenamento mínimo, recuperação cara (horas a dias)
  - Quando usar: implementar políticas automáticas de ciclo de vida (lifecycle policies) para migrar dados entre camadas; TTL para dados quentes em cache

- **Separação Computação ↔ Armazenamento vs Colocation Híbrido**:
  - **Puro colocation** (Hadoop/HDFS): processamento local ao dado; máxima largura de banda; cluster permanente e caro
  - **Separação pura**: object storage + clusters efêmeros; opex-first; escala a zero; latência de rede é o gargalo
  - **Híbrido** (padrão atual): object storage para durabilidade + cache local (HDFS/SSD) durante processamento; EMR+S3+HDFS, Spark in-memory, Druid+SSD+S3, BigQuery Colossus
  - Regra: separação por padrão; adicionar colocation onde a latência de rede é o gargalo real

- **Schema-on-Write vs Schema-on-Read**:
  - **On-write**: esquema aplicado na gravação; padrão data warehouse; dados fáceis de consumir; exige schema registry
  - **On-read**: esquema inferido na leitura; padrão data lake flexível; adequado para Parquet/JSON (com esquema embutido); CSV = problema — inconsistências acumuladas
  - Regra: on-write quando qualidade e governança são prioridade; on-read quando ingestão de dados heterogêneos é o requisito

## Key Concepts

- **HDD (disco magnético)**: ~$0,03/GB; 300 MB/s sequencial; 50–500 IOPS; 4ms latência aleatória; valor em armazenamento de massa + paralelismo (base do object storage)
- **SSD**: ~$0,20/GB; GBs/s; dezenas de milhares IOPS; <0,1ms; padrão para OLTP; papel crescente em OLAP (cache de dados quentes)
- **RAM**: ~$10/GB; 100 GB/s; milhões de IOPS; 0,1μs; volátil — perde dados sem energia; base do Spark in-memory, Redis, caches de consulta
- **Serialização**: conversão de dados em formato padrão para disco/rede; row-oriented = bom para OLTP (update no local); column-oriented = bom para OLAP (varredura + compressão); formatos relevantes: Parquet (colunar), Arrow (in-memory), Hudi (híbrido com capacidade de upsert)
- **Compressão**: 3 vantagens — menor espaço em disco, varredura mais rápida (10:1 ratio → 300 MB/s efetivos = 3 GB/s), largura de banda de rede efetiva maior; custo: CPU adicional para comprimir/descomprimir
- **Object storage**: armazenamento chave-valor de objetos imutáveis; sem gravação aleatória; gravado uma vez, relido muitas vezes; paralelismo massivo via múltiplos fluxos; durabilidade multi-zona; base dos data lakes em nuvem e da separação computação-armazenamento
- **Consistência eventual vs forte**: eventual = leitura pode retornar versão desatualizada; forte = garante versão mais recente sempre; DynamoDB suporta ambos (strong consistency = mais caro)
- **Versionamento de objetos**: manter versões antigas de objetos sob a mesma chave; resolve inconsistência eventual ao referenciar versão específica; custo = armazenamento completo por versão (sem delta)
- **Zero-Copy Cloning**: shallow copy — cria nova tabela virtual apontando para os mesmos arquivos físicos; sem custo de cópia; risco: deletar objeto original pode destruir o clone
- **HDFS**: sistema de arquivos distribuído; combina computação + armazenamento nos mesmos nós; bloco ~100-500 MB com replicação em 3 nós; NameNode gerencia metadados; ainda presente em legado e EMR
- **Data lakehouse**: arquitetura que adiciona capacidades de DW (ACID, schema, upsert, histórico de tabelas) sobre object storage; implementações: Delta Lake (Databricks), Apache Hudi, Apache Iceberg; vantagem sobre DW proprietário: interoperabilidade de ferramentas
- **Micro-particionamento Snowflake**: conjuntos de 50–500 MB com metadados de intervalo de valores; pruning automático por predicado; banco de metadados funciona como índice sem índice explícito
- **Particionamento vs Clustering**: particionamento = divide tabela em sub-tabelas por campo (data, região); clustering = ordena dados dentro das partições para filtros mais eficientes
- **Catálogo de dados**: repositório centralizado de metadados; integra linhagem, relacionamentos, descoberta de dados; varredura automática + camada social (wiki); base do data lakehouse para descoberta de tabelas
- **Single-tenant vs multi-tenant**: single = banco dedicado por cliente (isolamento total, esquemas podem divergir); multi = todos clientes no mesmo banco (eficiência, requer controle de acesso granular)
- **Retenção de dados**: decisão por valor (impossível de recriar?), tempo (frequência de acesso downstream), compliance (HIPAA, PCI, GDPR) e custo (ROI do armazenamento)
- **Replay**: mecanismo de recuperação de dados históricos em plataformas de streaming (Kafka, Kinesis); permite reprocessamento de pipelines e consultas em lote sobre stream histórico

## Mental Models

- "Cada camada da hierarquia de cache é ~10x mais cara e ~10x mais rápida que a anterior — construa para o nível mais barato que atenda ao SLA."
- "Object storage = serverless desde o início: esconde clusters de disco, paraleliza leituras, escala para exabytes — mas é imutável e tem latência de 100ms."
- "BASE não é inferior ao ACID — é uma compensação deliberada de consistência por escala; saiba qual você está usando."
- "Separação computação-armazenamento não significa abrir mão de performance — significa cache estratégico no lugar certo (EMR+HDFS, Druid+SSD) com durabilidade no object storage."
- "Schema-on-read parece flexível até você precisar processar os dados — CSV sem contrato é uma bomba de dívida técnica."

## Anti-patterns

- **WORM data lake sem governança**: "grave uma vez, nunca leia" — sem capacidade de update/delete; problema com GDPR e inconsistências; solução: lakehouse com Delta/Hudi/Iceberg
- **Armazenamento quente para tudo**: acesso rápido a qualquer dado — custo proibitivo; implementar lifecycle policies para migrar dados mornos e frios automaticamente
- **Zero-copy cloning sem entender shallow copy**: deletar objeto original destrói o clone; usar deep copy quando durabilidade do clone é necessária
- **Object storage como sistema de arquivos de alta frequência**: montar S3 como disco local para gravações transacionais frequentes — sobrecarga de operações e custo de request por escritas pequenas
- **CSV como formato de data lake**: sem esquema embutido, inconsistências de tipos, sem compressão eficiente — usar Parquet ou JSON com schema registry
- **HDFS em cluster permanente pequeno**: overhead de NameNode + custo fixo sem os benefícios de escala do Big Data original; avaliar migração para object storage em nuvem
- **Sem lifecycle policy em object storage**: dados quentes nunca migram para camadas mais baratas; custos crescem linearmente com o volume sem necessidade

## Reference Tables

### Tipos de Armazenamento — Guia de Uso

| Sistema | Padrão de acesso | Latência | Uso principal | Limitação |
|---|---|---|---|---|
| RAM / Redis | Random, em memória | μs | Cache de sessão, feature store, leaderboard | Volátil, caro |
| SSD / EBS | Random read/write | <1ms | OLTP, bancos transacionais | Custo ~10x HDD |
| HDD / RAID | Sequential scan | 4ms | Armazenamento de massa, backups locais | Acesso aleatório lento |
| Object storage | Batch, streaming reads | 100ms | Data lake, durabilidade de longo prazo, ML data | Imutável, sem update local |
| Arquivístico (Glacier) | Raro | 12h | Compliance, backups de 7–10 anos | Recuperação cara e lenta |

### Abstrações de Armazenamento — Comparação

| Abstração | Base física | ACID | Schema enforcement | Ideal para |
|---|---|---|---|---|
| Data warehouse (DW) | MPP, SSD | Sim | On-write | BI estruturado, SQL analytics |
| Data lake 1.0 | HDFS / object storage | Não | On-read | Dados brutos, ML, não estruturado |
| Data lakehouse | Object storage + metadados | Sim (via Delta/Hudi) | Ambos | Unificação DW + lake, GDPR compliance |
| Data platform | Object storage + ecossistema | Depende do produto | Depende | One-stop shop, reduz integrações |

### Colocation vs Separação — Quando Aplicar

| Situação | Recomendação |
|---|---|
| Tarefa pontual de Big Data | Separação (cluster efêmero + object storage) |
| Consultas OLAP contínuas de baixa latência | Híbrido (cache SSD local + durabilidade em S3) |
| OLTP transacional de alta frequência | Colocation (SSD dedicado, baixa latência) |
| Conformidade + durabilidade de longo prazo | Object storage multi-zona |
| Streaming com replay histórico | Kafka/Kinesis (retenção longa em object storage) |

## Worked Example

**Pipeline EMR híbrido — separação + colocation na prática:**

Objetivo: processar 10 TB diários de logs de eventos em S3 → gerar agregações → gravar resultado em S3.

```
S3 (durabilidade)
  └── EMR cluster (efêmero)
        ├── HDFS local em SSD → cache das etapas intermediárias de processamento
        └── Spark jobs:
              1. Lê dados brutos do S3 → local HDFS  [evita re-leitura S3 por etapa]
              2. Processa + filtra → reduz volume em ~80%  [menos dados na rede]
              3. Grava resultado final → S3              [durabilidade]
              4. Cluster excluído → custo zero ocioso
```

**Por que funciona**: object storage garante durabilidade sem cluster permanente; HDFS local em SSD garante largura de banda para etapas intermediárias (evita latência de 100ms do S3 por cada leitura). Quando a tarefa termina, o cluster some — sem custo de HDD permanente.

**Lifecycle policy automática sobre os resultados no S3:**
- 0–30 dias: S3 Standard (quente — acesso diário para dashboards)
- 31–180 dias: S3 Infrequent Access (morno — ~mensal para auditorias)
- 180+ dias: S3 Glacier (frio — compliance, raramente acessado)

**Economia estimada**: lifecycle policies podem reduzir custo de armazenamento em 60–80% sem impacto no SLA para dados recentes.

## Key Takeaways

1. Armazenamento tem três camadas: componentes físicos → sistemas → abstrações; entender a camada abaixo sempre informa as compensações da acima.
2. A hierarquia de cache (CPU → RAM → SSD → HDD → object storage → arquivístico) é o mapa de decisão fundamental: escolher o nível mais barato que atenda ao SLA de latência.
3. Object storage é a base de data lakes modernos: imutável, massivamente paralelo, durável multi-zona, barato — mas não é adequado para transações de alta frequência.
4. Separação computação-armazenamento é o padrão em nuvem, mas na prática é sempre híbrida: cache local (SSD/HDFS/RAM) para performance, object storage para durabilidade.
5. Data lakehouse (Delta Lake, Hudi, Iceberg) resolve o problema do data lake 1.0: adiciona ACID, schema enforcement, update/delete e histórico de tabelas sobre object storage.
6. Lifecycle policies automáticas são obrigatórias: mover dados quentes → mornos → frios salva 60–80% do custo de armazenamento sem mudar o pipeline.
7. Schema-on-write > schema-on-read em governança; CSV sem contrato = dívida técnica acumulada; usar Parquet ou JSON com schema.

## Connects To

- **Ch3**: Arquitetura — data warehouse, data lake, lakehouse introduzidos; este capítulo aprofunda os mecanismos físicos e decisões de implementação
- **Ch4**: Escolha de tecnologias — TCO/TOCO se aplica diretamente a decisões de HDD vs SSD vs object storage; serverless-first = separação computação-armazenamento
- **Ch5**: Sistemas de origem — NoSQL taxonomy usa os mesmos sistemas de armazenamento descritos aqui (colunas amplas, grafos, séries temporais)
- **Ch7**: Ingestão — replay de streaming, padrões de ingestão incremental vs full load, object storage como destino
- **Ch8**: Transformação — particionamento, clustering, schema e modelagem de dados dependem diretamente das abstrações de armazenamento deste capítulo
- **DDIA (Kleppmann)**: referência externa para serialização, ACID, consistência distribuída e log-structured storage em profundidade

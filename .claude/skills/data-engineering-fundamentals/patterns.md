# Padrões Técnicos — Fundamentos de Engenharia de Dados

Padrões organizados por categoria. Cada padrão tem: condição de uso, estrutura, e trade-offs.

---

## 1. Padrões de Arquitetura

### Data Lakehouse
**Use quando**: precisa de flexibilidade de data lake (dados brutos, não estruturados) + garantias de DW (ACID, schema, query SQL).
```
Object Storage (S3/GCS/ADLS)
  + Camada de transações (Delta Lake / Hudi / Iceberg)
  → Engines de query (Spark, Trino, Athena, BigQuery Omni)
```
**Trade-off**: complexidade operacional maior que DW puro; melhor interoperabilidade de ferramentas. [ch03] [ch06]

---

### Padrão Estrangulador (Strangler)
**Use quando**: modernizando arquitetura legada sem reformulação total.
```
Sistema legado → ainda serve tráfego
Novo componente → criado em paralelo
Migração gradual → % do tráfego → novo
Legado deprecado → quando 0% do tráfego
```
**Trade-off**: processo lento mas reversível; evita "big bang" irreversível. [ch03]

---

### Lambda Architecture
**Use quando**: precisa de análise histórica (lote) + baixa latência (stream) e aceita dois code paths.
```
Origem → [Camada lote (Spark/Hive)] → Serving layer
       → [Camada stream (Flink/Kafka)] → Serving layer
```
**Trade-off**: duplicação de lógica; difícil manter consistência entre camadas. [ch03]

---

### Kappa Architecture
**Use quando**: equipe tem maturidade em streaming e quer código unificado.
```
Origem → Stream (Kafka/Kinesis) → Processamento (Flink/Spark Streaming) → Serving
                               → Replay histórico quando necessário
```
**Trade-off**: código unificado; custo e complexidade operacional maiores que Lambda. [ch03]

---

### Data Mesh
**Use quando**: organização grande com múltiplos domínios de negócio e bottleneck de equipe central de dados.
```
Domínio A → [Pipeline próprio] → [Produto de dados A] → Disponibiliza via contrato
Domínio B → [Pipeline próprio] → [Produto de dados B] → Disponibiliza via contrato
Plataforma central → infraestrutura self-service
Governança federada → padrões comuns sem centralização
```
**Trade-off**: ownership distribuído reduz bottleneck; exige maturidade técnica e cultural em todos os domínios. [ch03]

---

## 2. Padrões de Ingestão

### CDC Log-Based (Debezium → Kafka)
**Use quando**: precisa de replicação em tempo real com histórico completo de transações.
```
PostgreSQL/MySQL WAL
  → Debezium (CDC connector)
  → Kafka topic (retenção configurável)
  → Consumidores (Flink, Spark Streaming, S3 via Firehose)
```
**Trade-off**: captura todo evento; setup mais complexo; consome recursos do banco (WAL reading). [ch07]

---

### Webhook Resiliente com Buffer
**Use quando**: recebendo eventos externos via webhook com picos imprevisíveis.
```
Origem externa
  → Lambda (stateless, escala a zero)
  → Kinesis/Kafka (buffer: absorve picos + TTL para replay)
  → Flink/Spark Streaming (processamento assíncrono)
  → Dead-letter queue (eventos com erro, isolados)
  → S3 Parquet (durabilidade)
```
**Trade-off**: resiliente a picos; latência adicional do buffer; custo de Kinesis/Kafka. [ch07]

---

### EMR Híbrido (Separação + Cache Local)
**Use quando**: processando grandes volumes em lote com múltiplas etapas intermediárias.
```
S3 (durabilidade)
  → EMR cluster efêmero
      → HDFS local (SSD): etapas intermediárias
      → Spark jobs: processamento
      → S3 (resultado final)
  → Cluster excluído (custo zero em repouso)
```
**Trade-off**: evita latência de 100ms do S3 por etapa; custo do cluster durante processamento. [ch06]

---

### Snapshot vs. Incremental
**Use quando (snapshot)**: simplicidade > volume; tabelas pequenas; sistema de origem sem CDC.
**Use quando (incremental)**: volume é o gargalo; origem tem `updated_at` ou CDC.
```
Snapshot: SELECT * FROM tabela → gravar completo
Incremental: SELECT * FROM tabela WHERE updated_at > last_run → gravar delta
CDC log-based: ler WAL → capturar INSERT/UPDATE/DELETE → enviar para stream
```
**Limitação incremental por `updated_at`**: captura estado final, não histórico de transações. [ch07]

---

### Produção Sem Toque (Touchless Production)
**Use quando**: trabalhando com dados sensíveis em pipelines de dados.
```
Desenvolvimento → dados simulados / sintéticos
Deploy → automatizado (CI/CD)
Acesso excepcional → "quebra de vidro" (2 aprovações, auditado, revogado após uso)
```
**Trade-off**: reduz exposição de dados sensíveis; overhead de aprovação para debugging emergencial. [ch07]

---

## 3. Padrões de Armazenamento

### Lifecycle Policy Automática
**Use quando**: armazenando dados com frequência de acesso decrescente com o tempo.
```
0–30 dias: S3 Standard (~$0,023/GB) — queries diárias
31–180 dias: S3 Infrequent Access (~$0,0125/GB) — auditorias mensais
180+ dias: S3 Glacier (~$0,004/GB) — compliance, raramente acessado
```
**Economia**: 60–80% de redução de custo sem impacto no SLA para dados recentes. [ch06]

---

### Insert-Only + Deduplicação na Query
**Use quando**: precisando de histórico completo com writes baratos.
```
Novos eventos: INSERT com timestamp, nunca UPDATE
Estado atual: SELECT WHERE timestamp = MAX(timestamp) GROUP BY key
Auditoria: SELECT * WHERE key = X ORDER BY timestamp
```
**Trade-off**: writes baratos; leitura do estado atual mais cara; tabela cresce indefinidamente. [ch05] [ch08]

---

### SCD Tipo 2 (Dimensões com Histórico)
**Use quando**: modelando dimensões que mudam ao longo do tempo e o histórico importa.
```
Mudança de atributo:
1. UPDATE registro atual: EFF_EndDate = hoje - 1
2. INSERT novo registro: EFF_StartDate = hoje, EFF_EndDate = 9999-01-01
Query estado atual: WHERE EFF_EndDate = '9999-01-01'
Query histórico: WHERE EFF_StartDate <= data_referência AND EFF_EndDate >= data_referência
```
**Trade-off**: histórico completo; queries mais complexas; tabela cresce com cada mudança. [ch08]

---

### Data Lakehouse com Hudi para CDC
**Use quando**: precisando de updates frequentes (CDC) em dados analíticos.
```
CDC stream (Avro) → Hudi table:
  ├── Row-based layer: writes recentes (rápidos)
  ├── Columnar layer: dados históricos (leituras analíticas)
  └── Repacking periódico: funde row → columnar
```
**Trade-off**: write rápido + read analítico eficiente; complexidade operacional adicional. [ch11]

---

## 4. Padrões de Transformação

### Esquema Estrela (Kimball)
**Use quando**: construindo DW bottom-up para análise de negócios; iteração rápida.
```
fato_pedidos(OrderID, CustomerKey, DateKey, ProductKey, Amount)
dim_cliente(CustomerKey, Nome, Cidade, EFF_Start, EFF_End)  ← SCD Tipo 2
dim_data(DateKey, Data, Ano, Mês, Trimestre, DiaSemana)
dim_produto(ProductKey, Nome, Categoria, Preço)
```
**Trade-off**: fácil de iterar e entender para negócios; redundância nas dimensões. [ch08]

---

### ELT com Camada Semântica (dbt + LookML)
**Use quando**: precisando de definições de métricas centralizadas reutilizáveis.
```
Origem → [Load: Fivetran/Airbyte] → DW (raw)
       → [dbt: transformações SQL] → DW (staging → marts)
       → [dbt metrics / LookML] → camada semântica
       → [Looker / BI] → relatórios e dashboards
"Grave uma vez, use em qualquer lugar"
```
**Trade-off**: centraliza lógica de negócio; elimina inconsistências de métricas; curva de aprendizado. [ch08] [ch09]

---

### Streaming com Janelas
**Use quando**: processando dados de streaming com necessidade de agregações em tempo.
```
Janela de sessão: delimita por inatividade (ex: 30min sem evento = nova sessão)
Janela cascata: intervalos regulares (ex: contagem por hora)
Janela deslizante: sobreposição (ex: média móvel de 5min atualizada a cada 1min)
Watermark: define atraso máximo aceito (ex: aceitar late data até 10min após janela)
```
**Trade-off**: expressividade para padrões temporais; complexidade de tuning de watermarks. [ch08]

---

### Camada Semântica (Métricas Centralizadas)
**Use quando**: múltiplas squads calculam a mesma métrica de formas diferentes.
```
Sem camada semântica:
  Squad A: "clientes" = todos com pedido
  Squad B: "clientes" = todos com conta ativa
  → inconsistência silenciosa

Com camada semântica (dbt metrics / LookML):
  customers = usuarios WHERE status = 'active' AND pedidos_total > 0
  → definição única, usada por todos
```
**Trade-off**: fonte única de verdade; overhead de manutenção da camada. [ch08] [ch09]

---

## 5. Padrões de Disponibilização

### ETL Reverso com Guardrails
**Use quando**: devolvendo dados analíticos para sistemas operacionais (CRM, plataformas de anúncio).
```
DW (lead_score) → ETL Reverso (Hightouch/Census) → CRM (Salesforce)
Guardrails obrigatórios:
  ├── Limite de registros por run (ex: máx 10.000)
  ├── Alerta se delta > threshold (ex: lead_score_delta > 50%)
  └── Circuit breaker: pausa automática em anomalia
```
**Trade-off**: reduz atrito do usuário final; risco de loop de feedback sem controle. [ch09]

---

### Real-Time Stack (STL)
**Use quando**: migrando de MDS batch-first para arquitetura em tempo real.
```
MDS (atual):
  OLTP →[batch]→ DW →[dbt]→ BI

Real-Time Stack (futuro):
  OLTP →[CDC Debezium]→ Kafka
    → [Flink: STL — transform em movimento]
    → ClickHouse (analytics sub-segundo)
    → Feature Store (ML em tempo real)
    → Iceberg/Hudi (histórico)
```
**Trade-off**: latência sub-segundo; complexidade operacional significativamente maior. [ch11]

---

### Análise Incorporada com OLAP
**Use quando**: disponibilizando analytics para usuários externos da aplicação (SaaS B2B).
```
Usuário da aplicação → query
  → OLAP (Druid / ClickHouse / SingleStore)
      ├── Ingestão contínua de eventos
      ├── Particionamento + clustering por time
      └── Query sub-segundo com alta concorrência
  → Dashboard embutido na aplicação (iframe / API)
```
**Trade-off**: baixa latência + alta concorrência; custo de OLAP dedicado. [ch09]

---

## 6. Padrões de Segurança

### Política de Privilégio Mínimo
**Use quando**: definindo permissões para qualquer usuário ou sistema.
```
Humanos: IAM role com escopo exato; grupo por papel (analista/cientista/engenheiro)
Sistemas: conta de serviço com permissão mínima (ex: apenas INSERT em tabela específica)
Emergências: processo de "quebra de vidro" (aprovação, auditado, revogado após uso)
Revisão: revogar permissões não usadas por >30 dias
```
**Anti-pattern**: admin para todos por conveniência — blast radius máximo em comprometimento. [ch10]

---

### Monitoramento de Segurança em 4 Camadas
**Use quando**: configurando baseline de segurança para time de dados.
```
1. Acesso: quem acessou o quê, quando, de onde; padrões incomuns
2. Recursos: picos inexplicados de CPU/memória/disco
3. Faturamento: alertas de orçamento (pico = possível exploração)
4. Permissões: relatório semanal de permissões não usadas há >30 dias
```
**Trade-off**: overhead de monitoramento; detecta comprometimento antes de dano real. [ch10]

---

## 7. Padrões de Serialização

### Serialização por Estágio do Pipeline
**Use quando**: definindo formato de dados em cada estágio do pipeline.
```
Ingestão (Kafka): Avro + Schema Registry
  → alta velocidade de escrita, schema versionado

Armazenamento histórico: Parquet + Snappy/Zstandard
  → compressão eficiente, queries OLAP rápidas

Updates frequentes (CDC): Hudi
  → row layer para writes + colunar para reads

Cross-system in-memory: Apache Arrow
  → zero-copy entre Spark ↔ Python ↔ R

Exportação legada: CSV (somente quando obrigatório)
  → sem schema, propenso a erros — evitar no meio do pipeline
```
[ch11]

---

### Compressão por Caso de Uso
**Use quando**: escolhendo algoritmo de compressão.
```
Alta taxa de compressão (texto em armazenamento): gzip, bzip2
Velocidade + baixa CPU (data lake, queries ad-hoc): Snappy
Equilíbrio velocidade + compressão (streaming, colunar): Zstandard, LZ4
NUNCA lossless para dados analíticos (resultados imprecisos)
```
[ch11]

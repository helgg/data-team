# Capítulo 5: Geração de Dados em Sistemas de Origem

## Core Idea
Sistemas de origem geram os dados que alimentam todo o ciclo de vida da engenharia de dados. O engenheiro **consome mas não controla** esses sistemas — o que exige compreensão profunda de como os dados são criados, que garantias os sistemas oferecem, e como negociar acordos formais com os proprietários upstream.

## Frameworks Introduzidos

- **Tipos de Timestamp — Framework dos 4 Tempos**:
  - **Hora do evento**: quando o evento ocorreu no sistema de origem; inclui timestamp original
  - **Hora da ingestão**: quando o evento chegou ao pipeline (fila, storage, BD)
  - **Hora do processamento**: quando uma transformação foi aplicada
  - **Tempo total de processamento**: duração ponta a ponta
  - Quando usar: registrar todos os 4 em cada evento para monitoramento de SLA e debugging de latência

- **Mensagem vs. Stream — Distinção Fundamental**:
  - **Mensagem**: sinal isolado entregue a um consumidor; removida após confirmação de recebimento; "esquecida" após entrega
  - **Stream**: log append-only de eventos ordenados; retidos por semanas/meses; permite replay e agregações históricas
  - Quando usar mensagens: roteamento entre microsserviços, ações discretas
  - Quando usar streams: análise de padrões, reprodução de histórico, múltiplos consumidores independentes

- **Contrato de Dados** (Denmore):
  - Acordo formalizado entre proprietário do sistema de origem e equipe de ingestão
  - Deve especificar: dados extraídos, método (full/incremental), frequência, contatos
  - Armazenar em local conhecido (GitHub, wiki interna); padronizar formato para integração programática
  - Complementado por SLA (o que esperar) e SLO (métricas de conformidade, ex: "99% uptime")

- **CRUD vs. Insert-Only**:
  - **CRUD**: Create/Read/Update/Delete — padrão para estado corrente; atualiza registros existentes
  - **Insert-only**: novas linhas com timestamp em vez de atualizar; mantém histórico; consulta estado corrente via `MAX(timestamp)`; adequado para auditoria
  - Compensações insert-only: tabelas crescem rápido; consulta de estado atual tem overhead de `MAX()`

## Key Concepts

- **Dados analógicos vs. digitais**: analógicos = fala, escrita, instrumentos (efêmeros); digitais = transações, eventos de app, IoT (persistíveis)
- **OLTP (Online Transaction Processing)**: banco de dados de aplicação; leituras/gravações de registros individuais em alta velocidade; não escala para análise massiva
- **OLAP (Online Analytical Processing)**: banco colunar otimizado para varredura massiva de dados; mínimo de bloco ~100MB; ineficiente para consultas de registros individuais; usado também como origem em ETL reverso e ML
- **ACID**: Atomicidade (tudo ou nada), Consistência (toda leitura retorna versão mais recente gravada), Isolamento (execuções concorrentes equivalem a execuções sequenciais), Durabilidade (commits nunca perdidos)
- **Consistência eventual**: bancos distribuídos que relaxam consistência forte para ganhar escala; leituras podem retornar estado desatualizado; saber o modelo de consistência é crítico
- **Transação atômica**: conjunto de alterações confirmadas como unidade indivisível; ex: transferência bancária (débito + crédito devem ambos ocorrer ou nenhum)
- **CDC (Change Data Capture)**: captura cada evento de alteração (INSERT/UPDATE/DELETE); métodos: binary log, triggers→fila, timestamp-based pull; base para replicação em tempo real e streaming de eventos de BD
- **Log de banco de dados (WAL — Write-Ahead Log)**: arquivo binário no formato nativo do BD; garante recuperação após falha; base para CDC
- **CRUD**: padrão de armazenamento persistente — Create, Read, Update, Delete; regra: dados devem ser criados antes de usados
- **Idempotência**: processar uma mensagem N vezes produz o mesmo resultado que processar uma vez; propriedade essencial em sistemas de mensagens com entrega "pelo menos uma vez"
- **NoSQL — tipos principais**:
  - **Chave-valor**: acesso por chave única; cache em memória (sessões web) ou durável (ecommerce); base para documentos e colunas amplas
  - **Documentos**: objetos JSON aninhados em coleções; sem joins nativos; esquema flexível; consistência eventual comum; ex: MongoDB
  - **Colunas amplas**: petabytes, milhões req/s, latência <10ms; um índice (row key); ex: Bigtable, DynamoDB; varreduras via CDC ou full scan
  - **Grafos**: nós + arestas; ideal para traversals de conectividade complexa; linguagens: SPARQL, Cypher, GQL; ex: Neo4j
  - **Busca**: pesquisa semântica de texto + análise de logs; ex: Elasticsearch, Solr, Algolia
  - **Séries temporais**: sequências cronológicas; medição regular ou baseada em eventos; buffers de memória para gravações intensas; ex: InfluxDB, Apache Druid
- **REST**: transferência de estado representacional; stateless; baseado em verbos HTTP; cada chamada independente; pouco padronizado na prática
- **GraphQL**: consulta múltiplos modelos em uma única request; mais expressivo que REST; retorna JSON análogo à query
- **Webhooks**: "APIs reversas" — origem envia para destino via HTTP POST quando evento ocorre; push em vez de pull
- **gRPC**: RPC bidirecional eficiente sobre HTTP/2; Protocol Buffers; criado pela Google; usado em Google Ads, GCP
- **Tópico**: coleção de eventos relacionados em plataforma de streaming; múltiplos produtores e consumidores
- **Partição de stream**: subdivisão do stream para paralelismo; chave de partição distribui mensagens; evitar hotspotting (concentração em poucas partições)
- **Compartilhamento de dados**: plataformas multilocatário (Snowflake, BigQuery) com políticas de segurança granulares; viabiliza mercados de dados e data mesh
- **Stakeholder de sistemas**: constrói e mantém os sistemas de origem (engenheiros de software, devs de app, terceiros)
- **Stakeholder de dados**: controla acesso aos dados (TI, governança, terceiros)

## Mental Models

- "O sistema de origem é problema de outra pessoa — até que ele quebre e afete seus relatórios."
- "Todo dado nasce como stream; lote é apenas uma forma de processar o stream em blocos."
- "Mensagem = sinal descartável; stream = log consultável — escolha pelo que o downstream precisa fazer com o histórico."
- "ACID sem conhecimento é receita para desastre em consistência eventual — saiba em qual modelo você está."
- "Contrato de dados antes do pipeline: acordo verbal é o mínimo; contrato escrito é o padrão."

## Anti-patterns

- **Tratar sistemas de origem como "problema de outro"**: engenheiros que ignoram sistemas upstream criam pipelines frágeis e ficam cegos a mudanças de esquema e falhas
- **Consultas analíticas diretas em OLTP**: funciona a curto prazo em escala pequena; degrada com volume e compete com transações de produção
- **Banco de documentos sem governança de esquema**: flexibilidade JSON → inconsistências cumulativas → dor de cabeça para ingestão downstream (ex: MongoDB sem schema registry)
- **Assumir ordenação FIFO sem garantia**: sistemas distribuídos não garantem ordem por padrão; design deve tolerar entrega fora de ordem
- **Hotspotting em partições**: chave de partição com distribuição não uniforme (ex: estado da EUA por população) → partições sobrecarregadas, outras ociosas
- **Sem SLA/contrato upstream**: expectativas implícitas → surpresas em produção; nenhuma base para cobrar qualidade ou uptime

## Reference Tables

### Tipos de Banco de Dados NoSQL — Guia de Seleção

| Tipo | Caso de uso ideal | Limitação principal | Exemplos |
|---|---|---|---|
| Chave-valor em memória | Cache de sessão, baixa latência | Dados temporários (sem persistência default) | Redis, Memcached |
| Documentos | Estado de aplicação flexível, sem joins | Sem ACID nativo, consistência eventual | MongoDB, Firestore |
| Colunas amplas | IoT, fintech, ad-tech — alto volume, baixa latência | Apenas um índice (row key), sem joins | Bigtable, DynamoDB, HBase |
| Grafos | Redes sociais, recomendação, traversals complexos | Queries analíticas pesadas sobrecarregam produção | Neo4j, Neptune |
| Busca | Pesquisa de texto, análise de logs | Não substitui BD transacional | Elasticsearch, Solr |
| Séries temporais | Sensores IoT, logs, métricas operacionais | Joins limitados, não adequado para BI | InfluxDB, TimescaleDB |

### APIs — Comparação de Paradigmas

| Paradigma | Direção | Padrão | Uso principal |
|---|---|---|---|
| REST | Pull (cliente → servidor) | HTTP verbos; sem estado | APIs web genéricas |
| GraphQL | Pull (cliente → servidor) | Query única, múltiplos modelos | APIs flexíveis, mobile |
| Webhook | Push (servidor → cliente) | HTTP POST em evento | Notificações em tempo real |
| gRPC | Bidirecional | HTTP/2 + Protocol Buffers | Serviços internos, baixa latência |

### Mensagens vs. Streams — Decisão

| Critério | Fila de Mensagens | Plataforma de Streaming |
|---|---|---|
| Retenção após consumo | Removida | Retida (semanas/meses) |
| Replay de histórico | Não | Sim |
| Múltiplos consumidores independentes | Limitado | Nativo |
| Garantia de ordenação | Imprecisa (FIFO best-effort) | Por partição |
| Caso de uso típico | Microsserviços, RPC | Analytics, CDC, event sourcing |

## Worked Example

**Um tópico, dois consumidores — stream como ponte entre operações e analytics:**

Sistema de ecommerce publica eventos no tópico `web_orders`:
```json
{
  "Key": "Order #12345",
  "Value": "SKU 123, purchase price $100",
  "Timestamp": "2023-01-02T06:01:00Z"
}
```

**Consumidor 1 — Fulfillment** (operacional): recebe evento → aciona processo de separação/envio → não precisa de histórico
**Consumidor 2 — Marketing** (analítico): acumula eventos → treina modelo de ML para otimizar campanhas → precisa reproduzir histórico

**Insight arquitetural**: a mesma plataforma de streaming serve simultaneamente como sistema de origem (para o pipeline de dados), sistema de ingestão (captura CDC do OLTP), e barramento de eventos (para microsserviços) — as fronteiras do ciclo de vida são tênues em arquiteturas orientadas a eventos. Isso justifica tratar filas/streams como elemento subjacente transversal, não apenas uma etapa.

## Key Takeaways

1. Sistemas de origem estão fora do controle do engenheiro de dados — mas não da responsabilidade; estabeleça contratos de dados e SLAs com proprietários upstream.
2. Registre os 4 tipos de timestamp (evento, ingestão, processamento, total) em cada etapa do pipeline — são a base para SLA e debugging.
3. Mensagem ≠ stream: mensagem é descartável após entrega; stream é log replayável com retenção longa — escolha pelo que o downstream precisa.
4. ACID garante consistência; consistência eventual exige design idempotente — saiba qual modelo seu banco adota antes de construir o pipeline.
5. NoSQL não é uma categoria única: grafos, colunas amplas, documentos e séries temporais têm casos de uso, limitações e estratégias de extração completamente diferentes.
6. Contrato de dados + SLO são o mínimo para trabalhar com sistemas upstream confiáveis — expectativas verbais são insuficientes em produção.

## Connects To

- **Ch2**: Ciclo de vida — geração é a primeira etapa; elementos subjacentes (segurança, DataOps) se aplicam aqui com restrições de controle
- **Ch7**: Ingestão — como extrair dados de cada tipo de sistema de origem (CDC, full scan, APIs, webhooks)
- **Ch8**: Transformação — modelagem de dados assume conhecimento dos tipos de dados de origem (OLTP normalizado, documentos, grafos)
- **Ch10**: Segurança — credenciais, VPN, criptografia em repouso e em trânsito a partir dos sistemas de origem
- **DDIA (Kleppmann)**: referência externa para ACID, consistência eventual, replicação e logs de banco de dados em profundidade

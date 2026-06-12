# Capítulo 7: Ingestão

## Core Idea
Ingestão é o processo de mover dados de sistemas de origem para armazenamento — o "encanamento" do ciclo de vida. Qualquer design de ingestão exige responder oito perguntas sobre a natureza dos dados antes de escolher qualquer tecnologia: limitação, frequência, acoplamento, serialização, escalabilidade, confiabilidade, carga útil e padrão de movimentação (push/pull/poll).

## Frameworks Introduzidos

- **Dados Limitados vs. Ilimitados — Mantra do Capítulo**:
  - Todo dado é ilimitado até ser limitado artificialmente por um processo de negócio
  - Ingestão em lote = convenção imposta sobre dados naturalmente contínuos
  - Streaming preserva a natureza ilimitada para que etapas downstream também processem de forma contínua
  - Regra: ao projetar, pergunte "onde quero impor o limite?" — não assuma que lote é o padrão

- **8 Fatores de Design de Ingestão**:

| Fator | O que avaliar |
|---|---|
| Limitado vs. ilimitado | Dado é naturalmente contínuo? Qual é o caso de uso downstream? |
| Frequência | Lote (diário/horário), microlote ou streaming contínuo? |
| Síncrono vs. assíncrono | Etapas fortemente acopladas ou eventos independentes? |
| Serialização/desserialização | Destino consegue desserializar o formato que a origem envia? |
| Taxa de transferência e escalabilidade | Serviço gerenciado que escala ou cluster manual? |
| Confiabilidade e durabilidade | Custo de perda de dados vs. custo de redundância? |
| Carga útil | Tipo, forma, tamanho, esquema, metadados |
| Push vs. pull vs. poll | Quem inicia o movimento? Com que frequência? |

- **Ingestão Síncrona vs. Assíncrona**:
  - **Síncrona**: A→B→C fortemente acoplados; falha em B = reiniciar A+B+C; padrão de ETL legado; frágil
  - **Assíncrona**: cada evento flui independentemente; buffer (Kinesis, Kafka) absorve picos; paralelismo por cluster (Beam/Flink); taxa de processamento depende de recursos disponíveis
  - Regra: síncrono apenas para dependências reais de dados; assíncrono por padrão para resiliência

- **Snapshot Completo vs. Extração Diferencial**:
  - **Snapshot**: captura estado completo a cada leitura; simples de implementar; alto volume
  - **Diferencial (incremental)**: captura apenas alterações desde última leitura; menor volume e tráfego; mais complexo
  - Limitação do diferencial por `updated_at`: captura apenas estado final — não histórico intermediário de alterações
  - Regra: snapshot quando simplicidade > custo de volume; diferencial quando volume é o gargalo

- **CDC Batch vs. CDC Contínua vs. Replicação Síncrona**:
  - **CDC batch** (`updated_at`): consulta periódica; perde histórico de atualizações intermediárias; gera carga no banco
  - **CDC contínua (log-based)**: lê WAL (write-ahead log) sequencialmente; captura todo evento; ex: Debezium → Kafka
  - **Replicação síncrona**: réplica totalmente sincronizada com primário; sem perda de dados em failover; exige mesmo tipo de banco; útil como réplica de leitura para queries analíticas

- **Dead-Letter Queue**:
  - Fila separada para eventos que falham na ingestão (TTL expirado, tamanho excedido, tópico inexistente)
  - Sem dead-letter queue: eventos com erro bloqueiam ingestão de eventos válidos
  - Uso: diagnóstico de erros, reprocessamento após correção da causa raiz

## Key Concepts

- **Pipeline de dados**: combinação de arquitetura, sistemas e processos que movem dados pelas etapas do ciclo de vida; definição intencionalmente flexível — de ETL monolítico a 100 fontes + ML + monitoramento
- **Ingestão vs. integração**: ingestão = mover A→B; integração = combinar múltiplas fontes em novo conjunto de dados; ETL reverso = mover resultado analítico de volta para sistema operacional
- **Carga útil (payload)**: conjunto de dados sendo ingerido; características: tipo (tabular, imagem, áudio), forma (dimensões), tamanho (bytes), esquema, metadados
- **Forma dos dados**: dimensões da carga; tabular = M×N; JSON = profundidade de aninhamento; imagem = largura×altura×bits RGB; afeta compatibilidade com destino
- **Esquema registry**: repositório de metadados que versiona esquemas em streaming; garante consistência de serialização/desserialização entre produtores e consumidores
- **Evolução de esquema**: campos adicionados/removidos/alterados em eventos; pipeline deve detectar, versionar (schema registry) e rotear falhas (dead-letter queue)
- **Late data (dados atrasados)**: evento ocorre no tempo T mas chega na ingestão em T+delay; solução: definir watermark (horário limite) após o qual eventos tardios são descartados ou separados
- **TTL (tempo de vida de mensagem)**: tempo máximo que evento fica ativo antes de ser descartado se não consumido; Pub/Sub = 7 dias; Kinesis = 365 dias; Kafka = ilimitado (limitado por disco ou object storage)
- **Replay**: leitores solicitam mensagens de intervalo histórico; suportado por Kafka, Kinesis, Pub/Sub; não suportado por RabbitMQ (remove após consumo)
- **Conector de dados gerenciado**: plataforma SaaS/OSS que abstrai construção e manutenção de conectores; ex: Fivetran, Airbyte, Matillion; preferível a construir conectores customizados
- **JDBC/ODBC**: padrões de conexão a bancos relacionais; JDBC via JVM (portável entre linguagens JVM); ODBC via binário nativo; limitação: dados aninhados → texto → rede → texto; substituído por exports nativos (Parquet, Avro) em muitos casos
- **Appliance de transferência**: dispositivo físico para migração de volumes >100 TB; ex: AWS Snowball, AWS Snowmobile (caminhão com petabytes); mais econômico que egress pela internet em escalas extremas
- **Produção sem toque (touchless production)**: engenheiros desenvolvem em dados simulados; deploys automatizados em produção; reduz exposição a dados sensíveis; "quebra de vidro" requer aprovação de 2 pessoas para acesso excepcional
- **Datástrofe (datastrophe)**: regressão de dados silenciosa que distorce métricas de negócio sem aviso; dados são entrópicos — regressões ocorrem independente de deploys
- **Bastion host**: instância intermediária exposta à internet com acesso restrito; banco de dados nunca exposto diretamente; conexão: máquina remota → túnel SSH → bastion → banco

## Mental Models

- "Todos os dados são ilimitados até serem limitados — batch é uma convenção de negócio, não uma propriedade física dos dados."
- "Síncrono = fragilidade multiplicada: cada etapa acoplada é um ponto de falha total; assíncrono = buffer que absorve picos e falhas individuais."
- "Se você não coleta o dado sensível, não pode vazar — a primeira linha de defesa é não ingerir o que não precisa."
- "Dados são entrópicos: regressões ocorrem sem deploy, sem mudança de código, por razões externas — monitore continuamente, não apenas em produção."
- "Conectores de API gerenciados = mesma lógica de build vs. buy do Ch4: construir conector customizado é TOCO alto para tarefa com zero vantagem competitiva."

## Anti-patterns

- **Pipeline síncrono fortemente acoplado**: falha em uma etapa reinicia todo o pipeline; caso real: pipeline de 24h que reiniciava do zero em cada falha — produção sem relatórios por semanas
- **CDC em produção sem avaliação de carga**: CDC consome memória, disco, CPU e largura de banda; habilitar sem testes = risco de degradar banco de produção
- **`updated_at` como CDC completa**: captura apenas estado final, não histórico de transações intermediárias; banco de débitos/créditos perde 4 dos 5 saques do dia
- **Hash sem salting**: hash de e-mail sem salt é reversível — quem tiver o e-mail do cliente pode encontrá-lo nos dados; salting é obrigatório para anonimização real
- **Web scraping sem rate limiting**: criar centenas de Lambda simultâneos para scraping = DoS acidental no alvo; pode resultar em bloqueio de IP ou encerramento de conta AWS
- **Cron jobs como substituto de orquestração**: funciona para pipelines simples; escala não — sem dependência entre tarefas, sem reprocessamento, sem monitoramento real
- **Monitoramento negligenciado**: "assassino silencioso" — falha de pipeline que durou 6 meses sem detecção; dados desatualizados chegam a relatórios e decisões sem aviso

## Reference Tables

### CDC — Comparação de Abordagens

| Abordagem | Captura histórico? | Carga no banco | Caso de uso |
|---|---|---|---|
| CDC batch (`updated_at`) | Não (só estado final) | Moderada (query periódica) | Tabelas com insert-only ou frequência baixa |
| CDC contínua (log-based) | Sim (todo evento) | Baixa (lê WAL sequencial) | Replicação em tempo real, streaming analytics |
| Replicação síncrona | Sim (réplica exata) | Alta (acoplamento tight) | Alta disponibilidade, réplica de leitura OLTP |

### Formas de Ingestão — Guia de Seleção

| Forma | Quando usar | Limitação |
|---|---|---|
| JDBC/ODBC | Bancos relacionais sem export nativo | Dados aninhados → texto; paralelismo sobrecarrega origem |
| Export de arquivo (Parquet/Avro) | Bancos que suportam export nativo colunar | Push-only; depende de capacidade da origem |
| CDC log-based | Replicação em tempo real, streaming analytics | Setup complexo; consome recursos do banco |
| Conectores gerenciados (Fivetran/Airbyte) | APIs e SaaS padrão; centenas de conectores prontos | Custo de licença; customização limitada |
| Filas/streaming (Kafka/Kinesis) | IoT, eventos de app, CDC; replay necessário | Overhead operacional alto se auto-hospedado |
| Webhooks | Origem envia push em evento | Frágil se não amortecido (Lambda → Kinesis → Flink) |
| Appliance físico (Snowball) | Migração >100 TB | Evento único; latência de dias/semanas |
| Compartilhamento de dados | Datasets de terceiros em plataformas cloud | Não é posse — acesso pode ser revogado |

### Push vs. Pull vs. Poll

| Padrão | Quem inicia | Exemplo | Quando usar |
|---|---|---|---|
| Push | Origem → Destino | Webhook, Kafka Producer, export de arquivo | Origem controla quando dados estão prontos |
| Pull | Destino → Origem | JDBC query, Kafka Consumer pull, CDC | Destino controla frequência; varreduras controladas |
| Poll | Destino verifica periodicamente | CDC batch por `updated_at`, S3 event check | Origem não suporta push/notificação; frequência baixa |

## Worked Example

**Arquitetura de webhook resiliente na AWS — Lambda → Kinesis → Flink → S3:**

Problema: receber eventos de parceiro externo via webhook; parceiro faz POST para endpoint a cada transação.

```
Parceiro externo
  └── POST /webhook
        └── AWS Lambda (receptor sem estado)
              ├── valida payload
              ├── publica no Kinesis Data Stream (buffer)
              └── responde 200 OK imediatamente

Kinesis Data Stream
  └── Apache Flink (processamento assíncrono)
        ├── enriquecimento do evento
        ├── filtragem de duplicatas (entrega pelo menos uma vez)
        ├── agregações em janelas de tempo
        └── encaminha eventos com erro → dead-letter queue (Kinesis separado)

S3 (via Kinesis Data Firehose)
  └── objetos Parquet agrupados por hora
        └── lifecycle policy: Standard → IA → Glacier
```

**Por que cada camada existe:**
- **Lambda**: stateless, escala a zero, absorve picos de POST sem servidor permanente
- **Kinesis (buffer)**: desacopla Lambda do Flink; absorve picos de tráfego; TTL = 7 dias para replay
- **Flink**: processamento assíncrono; paralelismo; janelas de tempo para late data
- **Dead-letter queue**: isola eventos malformados sem bloquear pipeline principal
- **S3 + lifecycle**: armazenamento durável sem cluster permanente; custo decresce com o tempo

**Alerta de anti-pattern**: Lambda → banco de dados direto sem buffer = pico de tráfego derruba banco; Lambda → S3 sem Flink = sem processamento de late data; ambos padrões vistos em produção.

## Key Takeaways

1. Dados são naturalmente ilimitados; batch é uma convenção artificial — ao projetar ingestão, escolha conscientemente onde impor o limite, não apenas herde o padrão de lote.
2. Síncrono = fragilidade; assíncrono + buffer = resiliência; o buffer (Kinesis, Kafka) é o componente crítico que absorve picos e desacopla etapas.
3. CDC log-based captura histórico completo de transações; CDC por `updated_at` captura apenas estado final — para analytics financeiros ou auditoria, a diferença é crítica.
4. Conectores gerenciados (Fivetran, Airbyte) são a escolha padrão para APIs e SaaS — construir conector customizado só justifica quando gerenciado não suporta e TOCO compensa.
5. A carga útil tem 5 dimensões (tipo, forma, tamanho, esquema, metadados) — incompatibilidade em qualquer dimensão entre origem e destino cria dados inertes e inutilizáveis.
6. Monitoramento na ingestão não é opcional: falha não detectada por 6 meses é um caso real, não hipotético — monitore uptime, latência e volume desde o primeiro deploy.
7. Privacidade começa na ingestão: não coletar dado sensível desnecessário > criptografar > tokenizar; hash sem salting não é anonimização real.

## Connects To

- **Ch5**: Sistemas de origem — APIs, filas, streaming, CDC introduzidos; este capítulo detalha como extrair dados de cada tipo
- **Ch6**: Armazenamento — object storage como destino e staging intermediário; lifecycle policies sobre dados ingeridos; replay em Kafka/Kinesis
- **Ch8**: Transformação — ETL vs. ELT; schema management começa na ingestão; dados ingeridos viram inputs de transformação
- **Ch9**: Disponibilização — ETL reverso mencionado aqui; resultado analítico volta para CRM via ingestão reversa
- **Ch10**: Segurança — VPC endpoints, criptografia em trânsito, produção sem toque, tokenização com salting
- **Ch11**: Pilha moderna — conectores gerenciados (Fivetran, Airbyte) como ferramentas transitórias avaliadas pelo critério Ch4

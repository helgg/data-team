# Glossário — Fundamentos de Engenharia de Dados

Termos ordenados alfabeticamente com referência ao capítulo de origem.

---

## A

**ACID** — Atomicidade, Consistência, Isolamento, Durabilidade; garantias transacionais de bancos relacionais. [ch05] [ch06]

**Análise de negócios** — Insights históricos acionáveis; latência de minutos a dias; ferramentas: Tableau, Looker, Power BI. [ch09]

**Análise incorporada (embedded analytics)** — Análise voltada ao usuário final da aplicação; exige sub-segundo + alta concorrência. [ch02] [ch09]

**Análise operacional** — Ação imediata sobre dados; latência de segundos a minutos; dashboards em tempo real. [ch09]

**Apache Arrow** — Formato binário colunar em memória; compartilhado entre linguagens; elimina overhead de serialização cross-system. [ch11]

**Apache Beam** — Modelo de processamento unificado para dados limitados e ilimitados via janelas; base do Dataflow. [ch03]

**Appliance de transferência** — Dispositivo físico (Snowball, Snowmobile) para migração de volumes >100 TB; mais econômico que egress. [ch07]

**Arquitetura Kappa** — Tudo como stream; lote como caso especial de streaming; unificado mas caro. [ch03]

**Arquitetura Lambda** — Camadas separadas de lote + streaming + disponibilização; difícil manter dois code paths. [ch03]

**Arquitetura orientada a domínio** — Organização de responsabilidade de dados por domínio de negócio; base do Data Mesh. [ch03]

---

## B

**BASE** — Basically Available, Soft-state, Eventual consistency; modelo de consistência de bancos distribuídos. [ch06]

**Bastion host** — Instância intermediária exposta à internet; banco nunca exposto diretamente; conexão via túnel SSH. [ch07]

**Benchmark wars** — Comparações de desempenho manipuladas por fornecedores; datasets minúsculos + otimização assimétrica. [ch04]

**Big ball of mud** — Monolito crescendo sem modularização; resultado de ignorar complexidade acoplada. [ch03]

---

## C

**Capex vs. Opex** — Investimento inicial (hardware próprio) vs. pagamento conforme uso (nuvem); opex-first é o padrão recomendado. [ch04]

**Carga útil (payload)** — Conjunto de dados sendo ingerido; dimensões: tipo, forma, tamanho, esquema, metadados. [ch07]

**Catálogo de dados** — Repositório centralizado de metadados; integra linhagem, relacionamentos, descoberta de dados. [ch06]

**CDC (Change Data Capture)** — Captura cada evento de alteração no banco de origem; métodos: log-based (WAL), triggers, timestamp. [ch02] [ch05] [ch07]

**CDC contínua (log-based)** — Lê WAL sequencialmente; captura todo evento; base para replicação em tempo real. [ch07]

**Ciclo de vida da engenharia de dados** — Geração → Armazenamento → Ingestão → Transformação → Disponibilização + 6 elementos subjacentes. [ch01] [ch02]

**Clustering (armazenamento)** — Ordenação de dados dentro de partições para filtros mais eficientes. [ch06]

**Consistência eventual** — Leituras podem retornar estado desatualizado; modelo de bancos distribuídos escaláveis. [ch05] [ch06]

**Conector de dados gerenciado** — Plataforma SaaS/OSS que abstrai construção de conectores; ex: Fivetran, Airbyte. [ch07]

**Contrato de dados** — Acordo formalizado entre proprietário upstream e equipe de ingestão; especifica dados, método, frequência, contatos. [ch05]

**COW (Copy On Write)** — Reescrita de arquivo inteiro ao atualizar em sistemas colunares; upserts frequentes são caros. [ch08] [ch11]

**Criptografia em repouso** — Full-disk encryption em dispositivos e server-side em buckets/bancos; protege contra acesso físico. [ch10]

**Criptografia over the wire** — HTTPS obrigatório; FTP suscetível a man-in-the-middle mesmo com dados "públicos". [ch10]

**COSS (Commercial OSS)** — Versão gerenciada de OSS por fornecedor; ex: Databricks/Spark, Confluent/Kafka. [ch04]

**CRUD** — Create, Read, Update, Delete; padrão de armazenamento persistente para estado corrente. [ch05]

---

## D

**DAG (Directed Acyclic Graph)** — Grafo de dependências de tarefas em orquestração; expressa dependências, não apenas horários. [ch02]

**Dados de matéria escura** — Dados em planilhas (700M–2B usuários); aplicações interativas com análise programável. [ch11]

**Dados quentes/mornos/frios** — Classificação por frequência de acesso; determina camada de armazenamento e custo. [ch02] [ch06]

**Data lakehouse** — Arquitetura que adiciona ACID, schema, upsert e histórico ao object storage; ex: Delta Lake, Hudi, Iceberg. [ch03] [ch06]

**Data Mesh** — Arquitetura descentralizada: domínios como produtos + infraestrutura self-service + governança federada. [ch03] [ch09]

**Data Vault** — Modelagem analítica com Hubs (chaves), Links (relacionamentos), Satélites (atributos); insert-only; ágil. [ch08]

**Data Warehouse (DW)** — Hub centralizado para análise; MPP; separação OLAP/OLTP; schema-on-write. [ch03] [ch06]

**DataOps** — Automação + Observabilidade + Resposta a incidentes; cultura antes de ferramentas. [ch02]

**Datástrofe (datastrophe)** — Regressão de dados silenciosa que distorce métricas sem aviso; ocorre independente de deploys. [ch07]

**DCL (Data Control Language)** — Sub-linguagem SQL para controle de acesso (GRANT, REVOKE). [ch08]

**DDL (Data Definition Language)** — Sub-linguagem SQL para definição de objetos (CREATE, ALTER, DROP). [ch08]

**Dead-letter queue** — Fila separada para eventos que falham na ingestão; evita bloqueio do pipeline principal. [ch07]

**Decisões reversíveis (portas de mão dupla)** — Bezos: decisões que podem ser desfeitas; preferir sempre para ganhar velocidade. [ch03]

**DODD (Data Observability Driven Development)** — Observabilidade aplicada ao ciclo de vida dos dados como TDD é para software. [ch02]

**DML (Data Manipulation Language)** — Sub-linguagem SQL para manipulação de dados (INSERT, UPDATE, DELETE). [ch08]

---

## E

**Efeito Lindy** — Tecnologia estabelecida tende a continuar existindo; base para distinguir imutáveis de transitórias. [ch04]

**Elasticidade** — Sistema que se expande/contrai automaticamente; "escalar para zero" = desligamento em ociosidade. [ch03]

**Engenharia de culto à carga** — Equipes pequenas copiando práticas de grandes empresas tech sem contexto. [ch04]

**Engenheiro Tipo A / Tipo B** — Tipo A: opera com ferramentas gerenciadas; Tipo B: constrói sistemas customizados. [ch01]

**ETL** — Extract, Transform, Load; transformação antes do carregamento; padrão legado on-premises. [ch02]

**ELT** — Extract, Load, Transform; carrega primeiro, transforma no DW; padrão MDS moderno. [ch02] [ch08]

**ETL reverso (Reverse ETL / BLT)** — Dados processados no OLAP retornam a sistemas de origem (CRM, plataformas de anúncios). [ch02] [ch09]

**Evolução de esquema** — Campos adicionados/removidos/alterados em eventos ao longo do tempo. [ch07]

---

## F

**FinOps** — Gerenciamento de custo em nuvem como prática cultural colaborativa entre engenharia, finanças e negócio. [ch03] [ch04]

**Forma dos dados** — Dimensões da carga útil: tabular M×N, JSON aninhado, imagem H×W×RGB. [ch07]

---

## G

**Governança de dados** — Descoberta + Segurança + Responsabilização; metadados: negócio, técnico, operacional, referência. [ch02]

**Granularidade** — Nível de detalhe de uma tabela; modelar no menor nível possível; agregar é trivial, desagregar é impossível. [ch08]

**Gravidade dos dados (data gravity)** — Dados em nuvem atraem serviços; saída é custosa; lock-in real mesmo sem contrato. [ch04]

**gRPC** — RPC bidirecional sobre HTTP/2 com Protocol Buffers; criado pela Google; baixa latência. [ch05]

---

## H

**HDD** — Disco magnético; ~$0,03/GB; 300 MB/s sequencial; 4ms latência; base do object storage. [ch06]

**HDFS** — Sistema de arquivos distribuído Hadoop; bloco ~100–500 MB; replicação em 3 nós; base do legado Big Data. [ch06]

**Hierarquia de cache** — CPU (ns) → RAM (μs) → SSD (ms) → HDD → Object storage (100ms) → Arquivístico (12h). [ch06]

**Hudi** — Formato híbrido: row layer para writes rápidos + colunar para reads + repacking periódico; ideal para CDC. [ch11]

---

## I

**IaC (Infrastructure as Code)** — Infraestrutura declarada em código; Terraform, Helm; essencial para DataOps. [ch02]

**Iceberg** — Formato de tabela com snapshots; time travel + evolução de schema + escala de petabytes. [ch11]

**Idempotência** — Processar mensagem N vezes produz o mesmo resultado que processar uma vez; essencial em "pelo menos uma vez". [ch05]

**Insert-only** — Novas linhas com timestamp em vez de atualizar; mantém histórico completo. [ch05]

**Ingestão assíncrona** — Eventos independentes com buffer; paralelismo; resiliência a picos. [ch07]

**Ingestão síncrona** — Etapas fortemente acopladas; falha em uma = reiniciar todo o pipeline; frágil. [ch07]

---

## J

**JDBC/ODBC** — Padrões de conexão a bancos relacionais; dados aninhados → texto → rede; substituído por exports nativos em escala. [ch07]

---

## L

**Late data (dados atrasados)** — Evento ocorre em T mas chega no pipeline em T+delay; tratado com watermarks. [ch07]

**Lifecycle policy** — Migração automática de dados entre camadas de armazenamento; reduz custo em 60–80%. [ch06]

**Lift-and-shift** — Migrar servidores on-premises 1:1 para VMs na nuvem; válido como fase inicial; não é cloud-native. [ch04]

**Linhagem de dados** — Trilha de auditoria da origem e transformações; base para compliance (GDPR "direito ao esquecimento"). [ch02]

**LookML** — Linguagem de definição semântica do Looker; compila SQL executado no banco de origem (pushdown). [ch09]

---

## M

**MapReduce** — Processamento distribuído com tudo em disco; rígido mas escalável; base do Hadoop. [ch08]

**MDM (Master Data Management)** — Golden records — representação canônica de entidades (cliente, produto) entre sistemas. [ch02]

**Mensagem vs. stream** — Mensagem: sinal descartável; stream: log replayável com retenção longa. [ch05]

**Metadados de negócio** — Definições, regras, owners; responde "o que é um cliente?". [ch02]

**Metadados operacionais** — Logs de execução, IDs de job; responde "o que rodou quando?". [ch02]

**Metadados técnicos** — Esquema, linhagem, pipeline; responde "como chegou aqui?". [ch02]

**Micro-particionamento** — Snowflake: conjuntos de 50–500 MB com metadados de intervalo; pruning automático. [ch06]

**Monolito distribuído** — Sistema distribuído com dependências compartilhadas; pior dos dois mundos. [ch04]

---

## N

**Normalização (1NF/2NF/3NF)** — 1NF: valores atômicos + PK. 2NF: sem dependências parciais. 3NF: sem dependências transitivas. [ch08]

**NoSQL** — Família: chave-valor, documentos, colunas amplas, grafos, busca, séries temporais; cada um com casos e limitações distintos. [ch05]

---

## O

**Object storage** — Armazenamento chave-valor de objetos imutáveis; paralelismo massivo; durabilidade multi-zona; base dos data lakes. [ch06]

**OLAP** — Online Analytical Processing; banco colunar para varredura massiva; bloco mínimo ~100 MB. [ch05]

**OLTP** — Online Transaction Processing; banco transacional; leituras/gravações de registros individuais em alta velocidade. [ch05]

**Orquestração** — Coordena tarefas via DAG; Airflow, Dagster, Prefect; não é apenas agendador. [ch02]

---

## P

**Padrão estrangulador (Strangler)** — Novos sistemas substituem componentes legados incrementalmente; ideal para brownfield. [ch03]

**Parquet** — Formato colunar; padrão de interoperabilidade para data lakes; compressão eficiente para OLAP. [ch11]

**Particionamento** — Divisão de tabela em sub-tabelas por campo (data, região); reduz dados lidos por query. [ch06]

**Permission Sprawl (excesso de permissões)** — Acumulação de permissões não usadas; detectadas e revogadas por ferramentas modernas. [ch10]

**Princípio do privilégio mínimo** — Mínimo acesso necessário para o tempo necessário; aplica-se a humanos e sistemas igualmente. [ch09] [ch10]

**Produto de dados** — Produto que ajuda a alcançar objetivo via dados; deve ter caso de uso ("jobs to be done") claro. [ch09]

**Pruning** — Reduzir dados lidos: selecionar colunas necessárias + cluster/partition keys + predicados. [ch08]

**Push vs. Pull vs. Poll** — Push: origem envia; Pull: destino consulta; Poll: destino verifica periodicamente. [ch05] [ch07]

---

## Q

**Query pushdown** — Lógica compilada em SQL executada no banco de origem; ex: Looker/LookML não armazena dados localmente. [ch09]

---

## R

**RAM** — ~$10/GB; 100 GB/s; volátil; base do Spark in-memory, Redis, caches de consulta. [ch06]

**RDD (Resumé-Driven Development)** — Escolher tecnologia por valor de currículo; anti-padrão. [ch03]

**Real-Time Data Stack** — Sucessor da MDS; streaming-first + OLAP em tempo real (Druid, ClickHouse). [ch11]

**Replay** — Reprocessar eventos históricos de plataforma de streaming; suportado por Kafka, Kinesis, Pub/Sub. [ch06] [ch07]

**Responsabilidade compartilhada** — Provedor garante segurança DA nuvem; usuário garante segurança NA nuvem. [ch10]

**RPO (Recovery Point Objective)** — Perda máxima de dados aceitável após recuperação de falha. [ch03]

**RTO (Recovery Time Objective)** — Tempo máximo aceitável de inatividade após falha. [ch03]

---

## S

**SCD (Slowly Changing Dimension)** — Tipo 1: substitui; Tipo 2: novo registro + datas efetivas (padrão); Tipo 3: campo adicional. [ch08]

**Schema-on-read** — Esquema inferido na leitura; flexível para ingestão heterogênea; risco: inconsistências acumuladas. [ch06]

**Schema-on-write** — Esquema aplicado na gravação; padrão DW; qualidade e governança garantidas. [ch06]

**Schema registry** — Repositório de metadados que versiona esquemas em streaming; garante consistência entre produtores e consumidores. [ch07]

**Segurança ativa vs. compliance passivo** — Ativa: investigar vulnerabilidades reais; Passiva: checklists de papel. [ch10]

**Segurança zero-trust** — Cada acesso verificado individualmente; sem perímetro físico confiável; padrão na nuvem. [ch03] [ch10]

**Separação computação-armazenamento** — Object storage para durabilidade + clusters efêmeros; opex-first; escala a zero. [ch06]

**Serialização** — Conversão de dados para formato padrão em disco/rede; row-oriented para OLTP; colunar para OLAP. [ch06] [ch11]

**SLA (Service Level Agreement)** — Compromisso geral de serviço; ex: "dados disponíveis com qualidade". [ch09]

**SLO (Service Level Objective)** — Métrica verificável de conformidade; ex: "99% uptime, 95% dados sem defeitos". [ch09]

**Snapshot completo vs. incremental** — Snapshot: captura estado completo; Incremental: apenas alterações; trade-off volume vs. complexidade. [ch07]

**SPC (Statistical Process Control)** — Monitoramento estatístico de processos; aplicado a dados para detectar anomalias. [ch02]

**SSD** — ~$0,20/GB; GBs/s; >10.000 IOPS; <0,1ms; padrão para OLTP; cache de dados quentes em OLAP. [ch06]

**SSO + MFA** — Single Sign-On elimina senhas individuais; MFA torna roubo de credencial insuficiente. [ch10]

**STL (Stream Transform Load)** — Sucessor do ELT em tempo real; transformação migra do DW para o pipeline de streaming. [ch11]

---

## T

**TCO (Total Cost of Ownership)** — Custo total incluindo diretos e indiretos; incompleto sem TOCO. [ch04]

**Temperatura dos dados** — Quente/morno/frio; determina classe de armazenamento e custo. [ch02] [ch06]

**TOCO (Total Opportunity Cost of Ownership)** — Custo das oportunidades perdidas ao escolher uma tecnologia; complementar ao TCO. [ch04]

**Topico (stream)** — Coleção de eventos relacionados em plataforma de streaming; múltiplos produtores e consumidores. [ch05]

**TTL (Time to Live)** — Tempo máximo que evento fica ativo antes de ser descartado; Pub/Sub: 7d; Kinesis: 365d; Kafka: ilimitado. [ch07]

---

## V

**VACUUM / Aspiração** — Remoção de registros obsoletos gerados por transações; crítico em PostgreSQL/MySQL. [ch08]

**Versionamento de objetos** — Manter versões antigas sob a mesma chave; resolve inconsistência eventual por referência de versão. [ch06]

**Virtualização de dados** — Trino/Presto consultam múltiplas fontes sem copiar; não isola carga do sistema de origem. [ch08]

**Visão materializada** — Transformação gerenciada pelo banco; resultado persistido; atualizado periodicamente. [ch08]

---

## W

**WAL (Write-Ahead Log)** — Log binário nativo do banco; garante recuperação após falha; base para CDC log-based. [ch05]

**Watermark** — Horário limite após o qual eventos tardios são descartados ou separados em streaming. [ch07]

**Webhooks** — "APIs reversas" — origem envia para destino via HTTP POST quando evento ocorre; push em vez de pull. [ch05]

**WORM / WORN** — Write Once Read Many / Write Once Read Never; anti-padrões de data lake sem governança. [ch02] [ch06]

---

## Z

**Zero-copy cloning** — Shallow copy: nova tabela virtual apontando para mesmos arquivos físicos; sem custo de cópia. [ch06]

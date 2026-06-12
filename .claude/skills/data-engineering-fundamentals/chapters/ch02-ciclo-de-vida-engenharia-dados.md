# Capítulo 2: O Ciclo de Vida da Engenharia de Dados

## Core Idea
O ciclo de vida da engenharia de dados — Geração → Armazenamento → Ingestão → Transformação → Disponibilização — é o framework central do livro. Ele redireciona o foco de tecnologias específicas para as etapas e os **elementos subjacentes** transversais que sustentam todo o ciclo.

## Frameworks Introduzidos

- **Ciclo de Vida da Engenharia de Dados (detalhado)**:
  - Geração, Armazenamento, Ingestão, Transformação, Disponibilização
  - Armazenamento age como base de sustentação (ocorre em todas as etapas)
  - Quando usar: como lente diagnóstica — "em qual etapa está o problema?"
  - Como: mapear cada decisão técnica a uma etapa; checar elementos subjacentes

- **Temperatura dos Dados**:
  - **Quente**: acessado várias vezes/dia ou por segundo; exige recuperação rápida
  - **Morno**: acesso regular (semanal/mensal)
  - **Frio**: raramente consultado; arquivamento; custo de escrita baixo, recuperação alto
  - Quando usar: ao escolher classe de armazenamento (SSD vs S3 Standard vs S3 Glacier)

- **Lote vs. Streaming**:
  - Todo dado nasce como stream; lote = forma especializada de processar stream em blocos
  - Streaming = dados disponíveis downstream em <1s; custo e complexidade maiores
  - Quando usar streaming: há caso de uso corporativo que justifica a latência; sistemas downstream suportam o fluxo
  - Regra: lote por padrão; streaming só com caso de uso claro e ROI demonstrado

- **Push vs. Pull (ingestão)**:
  - Push: origem envia para destino (ex: CDC com triggers)
  - Pull: sistema de ingestão consulta origem (ex: CDC baseada em timestamp, ETL tradicional)
  - Realidade: a maioria dos pipelines combina os dois modelos

- **DataOps — Três Pilares**:
  - **Automação**: CI/CD, pipelines como código, IaC; reduz erros manuais
  - **Observabilidade e Monitoramento**: SPC, DODD (Data Observability Driven Development); "dados são assassinos silenciosos"
  - **Resposta a Incidentes**: identificação proativa, comunicação sem julgamento, resolução ágil

- **Governança de Dados — Três Categorias**:
  - **Capacidade de Descoberta**: metadados (negócio, técnico, operacional, referência)
  - **Segurança**: controles de acesso, criptografia, tokenização
  - **Responsabilização**: ownership por tabela/campo; MDM (golden records)

## Key Concepts

- **Sistema de origem**: origem dos dados — banco transacional, IoT, fila de mensagens; engenheiro consome mas não controla
- **Esquema fixo vs. sem esquema**: esquema fixo = banco relacional; "sem esquema" = aplicação define ao gravar (Mongo, filas)
- **CDC (Change Data Capture)**: captura alterações em BD de origem; métodos: triggers → fila, binary log, timestamp-based pull
- **ETL Reverso**: dados processados → devolvidos a sistemas de origem/SaaS (CRM, Google Ads); padrão emergente via Hightouch/Census
- **Análise incorporada (embedded analytics)**: análise voltada ao cliente; multilocação com isolamento de dados por locatário
- **Metadados de negócio**: definições, regras, owners; responde "o que é um cliente?"
- **Metadados técnicos**: esquema, linhagem, pipeline; responde "como chegou aqui?"
- **Metadados operacionais**: logs de execução, IDs de job; responde "o que rodou quando?"
- **MDM (Master Data Management)**: golden records — representação canônica de entidades (cliente, produto) através de sistemas
- **Qualidade dos dados — 3 dimensões**: Precisão, Completude, Pontualidade
- **DODD**: observabilidade aplicada ao ciclo de vida dos dados como TDD é para software
- **Orquestração**: coordena tarefas via DAG (não apenas agendador); Airflow, Dagster, Prefect
- **IaC (Infrastructure as Code)**: infraestrutura declarada em código; Terraform, Helm; essencial para DataOps
- **Pipelines como código**: DAGs declarados em Python; tasks + dependências interpretadas pelo motor de orquestração
- **Linhagem de dados**: trilha de auditoria da origem e transformações; base para compliance (GDPR "direito ao esquecimento")
- **WORM / WORN / data swamp**: anti-padrões de armazenamento — dados gravados mas nunca lidos por falta de modelagem

## Mental Models

- "Lote por padrão; streaming somente quando o caso de uso justifica as compensações."
- "Dados são assassinos silenciosos — relatórios errados podem durar meses sem ninguém perceber."
- "Governança acidental produz dados não confiáveis; governança intencional maximiza valor e prevê crises."
- "Orquestração ≠ agendamento — DAGs expressam dependências, não apenas horários."
- "Cada byte armazenado em nuvem é uma linha no extrato do CFO — custo visível muda comportamento de retenção."

## Anti-patterns

- **Streaming por padrão sem caso de uso**: latência não se justifica; custo e complexidade superam o benefício na maioria dos casos
- **Cron jobs como orquestração**: sem dependências, sem visibilidade, falhas silenciosas; substitua por DAGs
- **Pular modelagem de dados**: resulta em data swamp / WORN — dados acumulados sem uso; exige conhecimento de Kimball, Inmon, Data Vault
- **Acesso de admin para todos**: violação do princípio do privilégio mínimo; "catástrofe esperando para acontecer"
- **Data lake como depósito infinito sem governança**: incentiva ignorar destruição e arquivamento; GDPR exige gerenciamento ativo
- **Implantar ML sem base de dados**: organizações lançam iniciativas de ML sem análise sólida e o projeto fracassa por falta de fundação

## Reference Tables

### Checklist de Avaliação — Sistema de Origem

| Pergunta | Por que importa |
|---|---|
| Taxa de geração (eventos/s, GB/h)? | Dimensiona ingestão e storage |
| Esquema muda com frequência? | Exige schema evolution strategy |
| CDC disponível (log, trigger, timestamp)? | Define método de ingestão |
| Leitura afeta desempenho da origem? | Risco de contenção de recursos |
| Quem é o owner do sistema de origem? | Comunicação de mudanças de esquema |

### Checklist de Avaliação — Sistema de Armazenamento

| Pergunta | Por que importa |
|---|---|
| Suporta velocidade de escrita/leitura necessária? | SLA downstream |
| Esquema fixo, flexível ou agnóstico? | Compatibilidade com transformações |
| Metadados e linhagem rastreados? | Governança e debugging |
| Compliance geográfico (soberania de dados)? | GDPR, LGPD |

### Lote vs. Streaming — Decisão

| Critério | Lote | Streaming |
|---|---|---|
| Latência necessária | Horas/dias OK | Segundos/milissegundos |
| Complexidade operacional | Baixa | Alta |
| Custo | Menor | Maior |
| Ferramentas maduras | Muito (Spark, SQL) | Crescendo (Flink, Pulsar) |
| Casos de uso típicos | Relatórios, ML training | Alertas, detecção de fraude |

## Worked Example

**Jornada de maturidade DataOps em uma equipe fictícia:**

| Estágio | Prática | Problema encontrado |
|---|---|---|
| 1 — Inicial | Cron jobs para transformações | Instância cai, tarefas param silenciosamente; analistas descobrem via relatório desatualizado |
| 2 — Orquestração | Migra para Airflow; tasks com dependências via DAG | Cientista implanta DAG defeituoso; derruba servidor web do Airflow |
| 3 — CI/CD | Deploy automatizado de DAGs; testes antes da implantação; validação de dependências Python | Falhas detectadas antes da produção; equipe tem menos "histórias de terror" |
| 4 — Observabilidade | SPC + DODD + alertas proativos | Time notifica stakeholders antes de serem questionados → confiança aumenta |

**Regra extraída**: "O gargalo no DataOps não é tecnologia — são hábitos culturais. Adote observabilidade primeiro, depois automação."

## Key Takeaways

1. O ciclo de vida (Geração → Armazenamento → Ingestão → Transformação → Disponibilização) é o modelo mental central; ferramentas mudam, etapas permanecem.
2. Armazenamento perpassa todas as etapas — não é apenas uma fase; temperatura dos dados (quente/morno/frio) guia a escolha de storage.
3. Lote por padrão; streaming só com caso de uso de negócio claro que justifica custo e complexidade.
4. Governança de dados = descoberta + segurança + responsabilização; metadados têm quatro tipos: negócio, técnico, operacional, referência.
5. DataOps = automação + observabilidade + resposta a incidentes; começa por cultura, depois ferramentas.
6. Orquestração via DAG (não cron): dependências explícitas, visibilidade, alertas, histórico.
7. ETL Reverso é padrão legítimo e crescente — dados transformados retornam a sistemas de origem/SaaS.

## Connects To

- **Ch3**: Arquitetura de dados — como projetar sistemas que atendem ao ciclo de vida
- **Ch5**: Sistemas de origem — detalhamento de cada tipo e suas características
- **Ch6**: Armazenamento — práticas recomendadas, data warehouse vs. data lakehouse
- **Ch7**: Ingestão — técnicas, ferramentas, lote vs. streaming na prática
- **Ch8**: Transformação — consultas, modelagem (Kimball, Inmon, Data Vault), streaming
- **Ch10**: Segurança — IAM, criptografia, governança em profundidade
- **DMBOK**: referência externa para gerenciamento de dados corporativo

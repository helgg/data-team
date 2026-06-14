# Chapter 10: Orchestrating the Data Pipeline

## Core Idea
Ingestão, transformação e carga são peças; orquestração é o que as une em produção. Um pipeline sem orquestração exige intervenção manual em cada etapa. Com orquestração, tarefas executam automaticamente na sequência correta, em paralelo onde possível, com retry em falhas soft e alertas em falhas hard — tudo sem intervenção humana.

## Frameworks Introduced

- **Pipeline Failure Classification**
  - **Hard failure**: erro que não se resolve com retry (data quality, permissões, código com bug) → pipeline para, alerta humano, ação corretiva necessária
  - **Soft failure**: erro transitório que pode desaparecer (network intermitente, upstream job ainda rodando) → resolver com retry + exponential backoff
  - Quando aplicar: ao especificar retry policy, classificar cada tipo de erro possível; não fazer retry de hard failures (desperdiça tempo e mascara o problema)

- **Trigger Type Selection**
  - **Schedule-based**: cron expression (ex.: `*/30 8-16 * * 2-6` = a cada 30min entre 8h–17h seg–sex); simples mas latência fixa
  - **Event-driven**: pipeline dispara quando evento ocorre (arquivo chegou no S3, upstream job completou); reduz latência entre dado disponível e processamento
  - **Manifest-based (hybrid)**: trigger só no arquivo manifest (enviado pelo parceiro ao fim do batch); garante que todo o batch chegou antes de processar
  - Quando usar: batch diário → schedule; chegada imprevisível de arquivos → event-driven; parceiro envia múltiplos arquivos em batch → manifest

- **Orchestration Tool Selection**
  - **AWS Data Pipeline**: legado (2012); em maintenance mode desde dez/2022; **não usar para novos projetos**
  - **AWS Glue Workflows**: Glue-only (Crawlers + ETL jobs); simples e integrado; não orquestra serviços fora do ecossistema Glue; retry configurado por job, não por workflow
  - **Amazon MWAA (Managed Airflow)**: Airflow open-source gerenciado; DAGs em Python; ecossistema amplo (AWS + third-party hooks/operators); custo fixo de infraestrutura (não serverless)
  - **AWS Step Functions**: serverless; visual designer + ASL (JSON); integração nativa com todos os serviços AWS (Lambda, Glue, EMR, SNS, etc.); retry/catch por estado; não suporta restart de state machine a partir de step específico
  - Regra de decisão: só Glue → Glue Workflows; ecossistema misto + open-source/portabilidade → MWAA; serverless + AWS-native + visual → Step Functions

## Key Concepts

- **DAG (Directed Acyclic Graph)**: grafo de tarefas onde fluxo é unidirecional e nunca retorna a nó anterior; Airflow exige DAG; Step Functions permite loops (não é estritamente DAG)
- **Exponential Backoff**: backoff multiplica delay entre retries; ex.: Step Functions `BackOffRate=1.5`, `IntervalSeconds=10` → retry 1: 10s, retry 2: 15s, retry 3: 22.5s; evita thundering herd
- **Manifest file**: arquivo enviado pelo produtor ao fim de um batch; lista arquivos + metadados (tamanho, hash SHA-256); pipeline só dispara quando manifest chega → valida completude do batch antes de processar
- **Step Functions State Machine**: conjunto de estados conectados; executado com JSON payload que cada estado pode ler e enriquecer; tipos de estado:
  - **Task**: executa trabalho (Lambda, Glue, EMR, SDK call)
  - **Choice**: branch condicional baseado em valor no payload
  - **Parallel**: execução paralela de múltiplos branches
  - **Pass**: modifica payload sem executar trabalho (útil para injetar dados de erro)
  - **Wait**: pausa por N segundos ou até timestamp
  - **Success / Fail**: estados terminais
- **Amazon States Language (ASL)**: JSON que define state machine; gerado pelo visual designer ou editado diretamente; versionável em source control; deployável via CI/CD
- **Amazon EventBridge**: event bus serverless; detecta eventos de serviços AWS (S3 PutObject, Glue job state change, etc.); filtra por padrão (bucket name, prefix, event type) e roteia para target (Step Functions, Lambda, SNS, etc.)
- **Airflow DAG**: definido em Python; cada task tem upstream/downstream dependencies; task states: None → Scheduled → Queued → Running → Success/Failed
- **Airflow Hooks**: código de conexão a sistemas remotos (S3, RDS, Slack); mantido separado do pipeline
- **Airflow Operators**: templates de task pré-construídos (BashOperator, PythonOperator, LambdaInvokeFunctionOperator); constroem sobre Hooks
- **Airflow Sensors**: operador especial que aguarda evento (S3KeySensor: espera key aparecer no S3); polling com timeout; habilita event-driven em Airflow
- **Glue Workflow batch trigger**: acumula N eventos EventBridge antes de disparar, com timeout máximo; ex.: aguarda 100 arquivos de parceiro OU 1 hora, o que ocorrer primeiro

## Reference Tables

### Comparação dos orquestradores AWS

| Critério | Glue Workflows | MWAA (Airflow) | Step Functions |
|---------|---------------|----------------|----------------|
| Serverless | Sim (Glue) | Não (infra gerenciada fixa) | Sim |
| Linguagem | Visual (Glue console) | Python (DAGs) | JSON (ASL) + visual designer |
| Integração AWS | Apenas Glue | Hooks/operators para muitos serviços | SDK integration para qualquer serviço AWS |
| Integração externa | Boto3 em Python Shell job | 200+ hooks/operators (DB, Slack, etc.) | SDK calls (menos conectores out-of-box) |
| Retry granularidade | Por Glue job | Por task | Por estado (Task, Parallel, etc.) |
| Restart de step específico | Sim (resume workflow) | Sim (clear task) | **Não** (reinicia do início) |
| Custo | Por DPU/hora Glue | Fixo (cluster sempre up) | Por state transition |
| DAG obrigatório | Não | **Sim** | Não (loops permitidos) |
| Quando usar | Pipeline 100% Glue | Portabilidade; equipe Python; third-party | AWS-native; serverless; visual dev |

### Tipos de falha e ação recomendada

| Tipo | Exemplos | Ação | Retry |
|------|----------|------|-------|
| Data quality | Arquivo JSON quando esperava CSV | Alertar, aguardar correção de upstream | Não |
| Code error | Sintaxe/lógica incorreta | Alertar, redeploy do código | Não |
| Permissions | IAM role sem acesso | Alertar, corrigir política | Não |
| Network transient | Timeout de conexão | Retry com backoff | Sim |
| Upstream delay | Job anterior ainda rodando | Retry com backoff | Sim |

## Worked Example

**Hands-on Ch10 — Step Functions + EventBridge: pipeline event-driven com error handling**

**Arquitetura**:
```
S3 Clean Zone (chapter10/) → EventBridge rule → Step Functions state machine
                                                     ├── Check File Extension (Lambda)
                                                     ├── Choice (.csv?)
                                                     │    ├── YES → Process CSV (Lambda) → Success
                                                     │    │         └── ERROR → SNS notification → Fail
                                                     │    └── NO  → Pass (inject error) → SNS notification → Fail
```

**Lambda 1 — detecta extensão do arquivo** (acionada por EventBridge payload):
```python
import urllib.parse, json, os

def lambda_handler(event, context):
    bucket = event['detail']['bucket']['name']
    key    = urllib.parse.unquote_plus(event['detail']['object']['key'])
    _, ext = os.path.splitext(key)
    return {"file_extension": ext, "bucket": bucket, "key": key}
```

**Lambda 2 — processamento com falha aleatória** (simula ETL em produção):
```python
from random import randint

def lambda_handler(event, context):
    value = randint(0, 2)   # 0 → ZeroDivisionError (33% chance)
    return 10 / value
```

**EventBridge rule — filtra S3 Object Created por prefix**:
```json
{
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": { "name": ["dataeng-clean-zone-<initials>"] },
    "object": { "key": [{ "prefix": "chapter10" }] }
  }
}
```

**Error handling no estado `Process CSV`**:
- Catch: `States.ALL` → Fallback = SNS Publish state; ResultPath = `$.Payload`
- Exponential backoff configurável: `IntervalSeconds=10`, `BackOffRate=1.5`, `MaxAttempts=3`

**Resultado dos testes**:
- Upload `.csv` → Choice entra em branch CSV → Lambda executa → ~33% falha com ZeroDivisionError → SNS email com `"Error":"ZeroDivisionError"`
- Upload `.pdf` → Choice cai no Default → Pass injeta `{"Error":"InvalidFileFormat"}` → SNS email com `"Error":"InvalidFileFormat"`
- Criação de prefix (folder) → falha imediata (extensão vazia, não é `.csv`) → SNS email

## Key Takeaways

1. Classificar falhas antes de configurar retry: hard failures não devem ter retry automático — perdem tempo e mascaram root cause; apenas soft failures (transient) se beneficiam de retry + backoff
2. Manifest file é o mecanismo correto para batches: trigger no arquivo manifest (ao fim do batch) garante completude antes de processar; evita N runs para N arquivos
3. Step Functions recomendado para AWS-native: visual designer acelera prototipação; ASL em JSON vai para source control; SDK integration cobre qualquer serviço sem operador dedicado
4. EventBridge filtra eventos com precisão: não é necessário receber todos os eventos de um bucket — filtrar por prefix/event type antes de disparar Step Functions reduz custo e evita runs desnecessários
5. Glue Workflows suficiente para pipelines puramente Glue: menos overhead que MWAA; não criar dependência de Airflow se pipeline só usa Glue Crawler + ETL jobs
6. MWAA é escolha quando portabilidade importa: DAGs Python rodáveis em qualquer Airflow (não apenas AWS); ecossistema open-source de 200+ conectores; custo fixo de infra é trade-off

## Connects To

- **Ch03**: Glue ETL jobs, Glue Crawlers, Glue Workflows, MWAA introduzidos no toolkit — orquestração aprofundada aqui
- **Ch06**: DMS + Kinesis Firehose eram acionados manualmente nos hands-on; em produção, EventBridge dispara pipeline quando dados chegam
- **Ch07**: Glue jobs de denormalização (Filme + Category) seriam Task states em um Step Functions state machine
- **Ch09**: COPY para Redshift seria um SDK integration state no pipeline Step Functions após transformação
- **Ch11**: Athena queries ad hoc não precisam de orquestração; pipelines agendados (relatórios diários) usam Step Functions com Athena SDK call

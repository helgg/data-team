# Chapter 16: Building a Modern Data Platform on AWS

## Core Idea
Uma modern data platform não é um único produto — é um conjunto de decisões arquiteturais sobre quais componentes usar (build vs buy), como deployar com segurança e reprodutibilidade (IaC + CI/CD), e como garantir que operações estejam visíveis e auditáveis (observability). DataOps aplica princípios de DevOps ao engenharia de dados: infraestrutura como código, deploy automatizado, testes unitários, e dashboards de saúde.

## Frameworks Introduced

- **Build vs Buy vs Open-source — decisão de plataforma**
  - **Buy (Databricks/Snowflake)**: plataforma integrada com storage, transformation engine, query editor, data services; componentes gerenciados pelo vendor; melhor para orgs sem DevOps/engenharia; custo premium; vendor lock-in; suporte multi-cloud
  - **Build (AWS-native)**: S3 + Glue/EMR + Athena/Redshift + Lake Formation + DataZone; flexibilidade máxima; custo menor; requer integrar componentes; ideal para orgs com DevOps skills e ambientes heterogêneos
  - **Open-source (SDLF)**: headstart com best practices; requer download + customização + integração; intermediário entre build e buy
  - Regra: sem DevOps → buy; startup/enterprise heterogênea → build; meio-termo → SDLF
  - Quando usar: antes de qualquer investimento em plataforma; decisão impacta 5–10 anos

- **DataOps = Automation + Observability**
  - **Automation**: deploy de infraestrutura via IaC (CloudFormation, Terraform); código de transformação em SCM (Git/CodeCommit); pipeline CI/CD deploy automático em cada commit; unit tests + security scan antes de deploy
  - **Observability**: dashboards (CloudWatch, Airflow) para KPIs de saúde; alerts (CloudWatch alarms, SLAs de Airflow) para falhas; logs centralizados (CloudWatch Logs, OpenSearch) para troubleshooting
  - Quando usar: toda data platform em produção; DataOps não é opcional — sem automação e observability, plataforma não é sustentável

## Key Concepts

### Goals da Modern Data Platform

- **Flexible e agile**: tecnologia muda constantemente (Iceberg, data mesh, Bedrock, EMR Serverless surgem ao longo de 1 edição do livro); platform deve suportar swap de componentes + incorporar novidades rapidamente; requer Agile development com sprints curtos
- **Scalable**: começar com MVP/MLP (Minimum Viable/Loveable Product) e crescer; onboarding por domínio — não tudo de uma vez; serverless AWS (S3, Kinesis on-demand, Lambda) elimina necessidade de re-arquitetar para escala
- **Well-governed**: governance não é add-on — é parte do MVP; suporta tanto governance central (compliance regulatório) quanto governance por domínio (requisitos específicos)
- **Secure**: dados em repouso e em trânsito encriptados; access control granular (column/row via Lake Formation); audit logs de acesso; Amazon Macie para detecção de PII em S3
- **Self-serve**: onboarding de domínios fácil; documentação clara; times adicionam data products + subscrevem datasets sem ticket para time central; tooling que não exige o time de plataforma para cada operação

### Componentes de Plataforma (build AWS-native)

| Componente | AWS Service |
|-----------|-------------|
| Storage | S3 (object) + Redshift RA3 (SQL-first) + Iceberg (OTF) |
| Transformation engine | Glue (PySpark), EMR (Spark/Presto), Athena (SQL), Lambda (Python leve) |
| Query editor | Redshift Query Editor (SQL DW), Athena (S3 lake) |
| Catalog | Glue Data Catalog (técnico) + DataZone (negócio) |
| Access control + sharing | Lake Formation |
| Data partner exchange | AWS Clean Rooms (privacy-preserving), AWS Data Exchange |

### SDLF — Serverless Data Lake Framework

Open-source por AWS Professional Services; implementado em Formula 1, Amazon Ireland, Naranja Finance.

- **Foundation**: S3 buckets, DynamoDB (configuração + tracking de execuções), ELK stack (monitoramento); compartilhado por todos os times
- **Teams**: recursos por grupo/domínio; cada time tem seus datasets, transformações, pipelines e repos
- **Datasets**: agrupamento lógico de dados — pode ser 1 tabela ou database completo (múltiplas tabelas, ex.: CDC de RDS)
- **Pipelines**: Step Functions orquestra múltiplos stages; Stage A = light transform (1 arquivo); Stage B = heavy transform (joins, business logic, agregações)
- **Transformations**: código (PySpark/Glue) que roda em cada stage; ex.: Stage A converte CSV → Parquet; Stage B join + agrega + escreve curated zone
- Requer DevOps skills; não é alternativa ao Databricks/Snowflake; acelera build-your-own com best practices embutidas

### DataOps — Automação de Infraestrutura

**Sem automação** (manual via console): sem histórico de mudanças; qualquer engineer pode mudar código sem revisão; sem como rastrear quem mudou o quê; rollback manual e arriscado.

**Com automação (IaC + SCM + CI/CD)**: cada mudança em infra ou código = commit revisado; pipeline deploy automático após aprovação; rollback = reverter commit; ambientes dev/test/prod com mesmos templates e parâmetros diferentes.

### AWS CloudFormation

IaC em YAML ou JSON; define recursos AWS e os deploya/atualiza automaticamente.

- **Parameters**: valores injetados no deploy (ScriptLocation, WorkerType, NumberOfWorkers); mesmo template → dev usa G.1X/2 workers; prod usa G.2X/10 workers
- **Integração com CodePipeline**: commit no template → pipeline detecta → CloudFormation atualiza resources automaticamente
- Multi-cloud ou non-AWS → Terraform (HashiCorp) equivale ao CloudFormation para qualquer provider

### AWS CDK (Cloud Development Kit)

Escreve recursos AWS em Python/TypeScript/Java/Go/C#; CDK converte para CloudFormation template.

- 13 linhas de Python CDK → 500+ linhas de CloudFormation (com best practices e secure defaults embutidos)
- Permite usar programação real: parâmetros, if/else, loops para definir múltiplos recursos
- Importa CloudFormation templates existentes → migração incremental
- Centraliza código de infra + código de transformação no mesmo repositório

### AWS CodeCommit

Managed Git; armazena código, binários e metadata com redundância; encriptação em repouso; IAM para permissões por repositório.

- 5 active users/mês grátis (Free Tier); $1/user adicional/mês
- Integra com Cloud9, VS Code, Eclipse; Glue tem integração nativa com CodeCommit e GitHub
- Pattern: 1 repo por domínio/data product (ex.: `data-product-film` com `glueETL_code/` + `cfn_templates/`)

### AWS CodeBuild

Compila, testa e empacota código; roda unit tests via Glue ECR Docker image antes de deploy; escreve output para S3.

### AWS CodePipeline

Continuous delivery; detecta commit via CloudWatch Events → executa stages (Source → Build → Deploy).

- **Pipeline de código**: CodeCommit commit → S3 copy (Glue jobs leem código do S3)
- **Pipeline de infra**: CodeCommit commit → CloudFormation create/update stack (Glue job config atualizado)

## Reference Tables

### Build vs Buy — decisão rápida

| Critério | Buy (Databricks/Snowflake) | Build (AWS-native) |
|---------|--------------------------|-------------------|
| DevOps/engenharia skills | Não necessário | Necessário |
| Custo | Premium (integração incluída) | Menor (paga só uso) |
| Flexibilidade de componentes | Limitada ao vendor | Alta |
| Suporte multi-cloud | Sim (ambos rodam em AWS+Azure+GCP) | Não nativo |
| Vendor lock-in | Alto | Baixo |
| Time de implementação | Menor | Maior |
| Ambientes heterogêneos | Difícil (forçar migração) | Melhor (integra diferentes tools) |
| Ideal para | Mid-size sem DevOps | Start-ups + grandes enterprises |

### AWS Services de DataOps — quando usar

| Necessidade | Serviço | Alternativa |
|------------|---------|-------------|
| Definir infra como código | CloudFormation | Terraform (multi-cloud) |
| Infra com linguagem de programação | AWS CDK | Pulumi |
| Repositório Git gerenciado | CodeCommit | GitHub, GitLab, Bitbucket |
| IDE browser-based na AWS | Cloud9 | VS Code + Remote SSH |
| Compilar/testar código | CodeBuild | GitHub Actions |
| CI/CD deploy automático | CodePipeline | GitHub Actions, GitLab CI |

### Observability — 3 camadas

| Camada | Ferramenta AWS | O que monitora |
|-------|---------------|----------------|
| Dashboards | CloudWatch Dashboards, Airflow UI | KPIs: throughput, execuções, status de DAGs |
| Alerts | CloudWatch Alarms, Airflow SLAs | Fila SQS crescendo, Lambda falhando, DAG atrasado |
| Logs | CloudWatch Logs, Amazon OpenSearch | Root cause de falhas; search avançado em logs |

## Worked Example

**Hands-on Ch16 — CodeCommit + CodePipeline: deploy automático de Glue job**

**Objetivo**: gerenciar código PySpark e CloudFormation template em Git; deploy automático via CodePipeline a cada commit.

**Setup — Cloud9 IDE**:
```bash
# Verificar Git
git --version

# Configurar identidade
git config --global user.name "Gareth Eagar"
git config --global user.email gareth.eagar@example.com

# Configurar credential helper para CodeCommit
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

# Criar diretório de trabalho
mkdir git && cd git
```

**Criar repositório CodeCommit + clonar**:
```bash
# Clonar repositório recém-criado
git clone https://git-codecommit.us-east-2.amazonaws.com/v1/repos/data-product-film

# Criar estrutura de diretórios
cd data-product-film
mkdir glueETL_code cfn_templates

# Criar bucket S3 para artefatos do data product
aws s3 mb s3://data-product-film-<initials>
```

**PySpark Glue script** (`glueETL_code/Glue-streaming_views_by_category.py`):
```python
# Loads streaming_films from Glue catalog, counts streams per category,
# writes Parquet to S3 and registers in Glue catalog as category_streams
StreamingFilms = glueContext.create_dynamic_frame.from_catalog(
    database="curatedzonedb", table_name="streaming_films",
    transformation_ctx="StreamingFilms"
)
spark_df = StreamingFilms.toDF()
spark_df.createOrReplaceTempView("streaming_films")

CategoryStreamsDF = glueContext.sql("""
    SELECT category_name, count(category_name) streams
    FROM streaming_films GROUP BY category_name
""")
CategoryStreamsDyf = DynamicFrame.fromDF(CategoryStreamsDF, glueContext, "out")

s3output = glueContext.getSink(
    path="s3://dataeng-curated-zone-<initials>/streaming/top_categories",
    connection_type="s3", updateBehavior="UPDATE_IN_DATABASE",
    compression="snappy", enableUpdateCatalog=True
)
s3output.setCatalogInfo(catalogDatabase="curatedzonedb",
                        catalogTableName="category_streams")
s3output.setFormat("glueparquet")
s3output.writeFrame(CategoryStreamsDyf)
```

**CloudFormation template** (`cfn_templates/CFN-glue_job-streams_by_category.cfn`):
```yaml
Parameters:
  JobName:
    Type: String
    Default: streaming_views_by_category
  IAMRoleName:
    Type: String
    Default: DataEngGlueCWS3CuratedZoneRole
  ScriptLocation:
    Type: String
    Default: "s3://data-product-film-<initials>/glueETL_code/Glue-streaming_views_by_category.py"

Resources:
  GlueJob:
    Type: AWS::Glue::Job
    Properties:
      Role: !Ref IAMRoleName
      Command:
        Name: glueetl
        ScriptLocation: !Ref ScriptLocation
      WorkerType: G.1X
      NumberOfWorkers: 2
      GlueVersion: "3.0"
      Name: Streaming Views by Category
```

**Commit para CodeCommit**:
```bash
git add .
git commit -m "Initial commit of CloudFormation template and Glue code for streaming views by category"
git push
```

**Pipeline 1 — deploy de código** (CodeCommit → S3):
```
Source: CodeCommit (data-product-film, branch master)
Change detection: CloudWatch Events
Build: skip
Deploy: Amazon S3 → data-product-film-<initials> bucket, extract files
→ Toda vez que código PySpark muda → novo arquivo copiado para S3 → próxima run do Glue usa versão atualizada
```

**Pipeline 2 — deploy de infra** (CodeCommit → CloudFormation):
```
Source: CodeCommit (data-product-film, branch master)
Deploy provider: AWS CloudFormation
Action mode: Create or update a stack
Stack name: glue-job-streaming-views-by-category-job
Template: cfn_templates/CFN-glue_job-streams_by_category.cfn
Role: DataEngGlueCWS3CuratedZoneRole (precisa de trust policy para cloudformation.amazonaws.com)
→ Commit no template → pipeline roda → CloudFormation atualiza Glue job
```

**Teste do pipeline** — aumentar workers via console CodeCommit:
```
Editar CFN template: NumberOfWorkers 2 → 3
Commit → pipeline In Progress → CloudFormation update → Glue job config atualizado
Verificar: Glue Console → Job details → Number of workers = 3
```

**IAM trust policy necessária** para `DataEngGlueCWS3CuratedZoneRole`:
```json
{
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": ["cloudformation.amazonaws.com", "glue.amazonaws.com"]
    },
    "Action": "sts:AssumeRole"
  }]
}
```

## Key Takeaways

1. Não existe "data platform pronta": buy simplifica integração mas cria lock-in; build oferece flexibilidade mas exige engenharia; SDLF acelera build com best practices; escolha depende de skills, budget e heterogeneidade do ambiente
2. IaC não é opcional em produção: deploy manual via console = sem histórico, sem rollback, sem revisão; CloudFormation/Terraform tornam infra auditável e reproduzível em múltiplos ambientes via parâmetros
3. SCM para código de transformação: Glue scripts no CodeCommit = cada mudança rastreada, revisada e aprovável; rollback = reverter commit; Glue lê script de S3 → CodePipeline sincroniza S3 automaticamente
4. CI/CD fecha o loop: commit de developer → pipeline detecta via CloudWatch Events → deploy automático sem ação humana; erros detectados em minutos, não em dias após deploy manual
5. Observability deve ser MVP: dashboards + alerts + logs centralizados devem existir desde o primeiro deploy; sem observability, falhas silenciosas em pipelines podem propagar dados errados por horas
6. AWS CDK supera CloudFormation puro: 13 linhas Python → 500+ linhas CFN com best practices; permite programação real (loops, condições); gerencia IaC no mesmo repositório que código de transformação
7. Platform goals = checklist de design: antes de qualquer decisão técnica, verificar se escolha satisfaz flexibility, scalability, governance, security e self-serve; falhar em qualquer um limita adoção da plataforma

## Connects To

- **Ch07**: Glue ETL scripts são os objetos gerenciados pelo CodeCommit/CodePipeline; CloudFormation deploya Glue jobs que rodam os scripts
- **Ch10**: Step Functions orquestra pipelines dentro do SDLF (Stage A → Stage B); DataOps automatiza deploy desses Step Functions workflows
- **Ch14**: Apache Iceberg como formato de storage em data platforms modernas; data product owners usam OTFs para garantir ACID e time travel
- **Ch15**: time central de plataforma (data mesh) é exatamente o time que gerencia e evolui a data platform descrita neste capítulo; DataOps é a metodologia que o time de plataforma usa
- **Ch04**: Lake Formation como camada de access control da plataforma; Amazon Macie para segurança de dados; ambos são componentes do "secure platform" goal

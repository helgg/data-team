# Arquitetura — Plataforma de Orquestração Serverless AWS

> Documento gerado pelo aws-architect. Serve como spec para o terraform-engineer.
> Data: 2026-06-11

---

## 1. Estrutura de Diretórios Definitiva

```
aws-infra/
├── backends/
│   ├── dev.tfbackend
│   └── prod.tfbackend
├── environments/
│   ├── dev.tfvars
│   └── prod.tfvars
├── modules/
│   ├── bootstrap/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── step-function/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── iam.tf
│   │   └── asl/
│   │       └── state_machine.json
│   └── s3-assets/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── locals.tf
├── versions.tf
├── sql/
│   └── example.sql
├── lib/
│   └── python/
│       └── utils.py
├── docs/
│   └── architecture.md
└── .gitignore
```

| Arquivo | Responsabilidade |
|---|---|
| `versions.tf` | `terraform` block com `required_version >= 1.5` e provider `aws ~> 5.x` |
| `main.tf` (root) | Instancia os módulos com passagem de variáveis |
| `variables.tf` (root) | Declara todas as variáveis de entrada do root module |
| `outputs.tf` (root) | Expõe ARNs relevantes (SF, S3 bucket, Log Group) |
| `locals.tf` (root) | Define `common_tags` e `name_prefix` |
| `backends/dev.tfbackend` | `bucket`, `key`, `region`, `encrypt = true` para DEV |
| `backends/prod.tfbackend` | Idem para PROD |
| `environments/dev.tfvars` | Valores de variáveis para DEV |
| `environments/prod.tfvars` | Valores de variáveis para PROD |
| `modules/bootstrap/main.tf` | Cria o bucket S3 de state backend |
| `modules/step-function/main.tf` | Cria a State Machine, Log Group e EventBridge Rules |
| `modules/step-function/iam.tf` | Cria apenas a EventBridge invoke role |
| `modules/step-function/asl/state_machine.json` | ASL placeholder com Pass states |
| `modules/s3-assets/main.tf` | Upload de assets SQL/Python via `for_each` |

---

## 2. Contrato de Variáveis por Módulo

### Root Module (`variables.tf`)

| Variável | Tipo | Descrição | Obrigatória |
|---|---|---|---|
| `aws_region` | `string` | Região AWS de deploy | Default: `"us-east-1"` |
| `environment` | `string` | Nome do ambiente (`dev` ou `prod`) | Sim |
| `project` | `string` | Nome do projeto (ex: `data-platform`) | Sim |
| `owner` | `string` | Time ou squad responsável | Sim |
| `cost_center` | `string` | Centro de custo para billing | Sim |
| `step_function_role_arn` | `string` | ARN da execution role já existente na conta | Sim |
| `glue_database_name` | `string` | Nome do Glue Database da tabela-origem monitorada | Sim |
| `glue_table_name` | `string` | Nome da tabela Glue a monitorar (trigger do EventBridge) | Sim |
| `assets_bucket_name` | `string` | Nome base do bucket de assets SQL/Python | Sim |
| `state_bucket_name` | `string` | Nome do bucket S3 de Terraform state | Sim |
| `sql_assets_path` | `string` | Path local dos arquivos SQL | Default: `"./sql"` |
| `python_assets_path` | `string` | Path local dos arquivos Python | Default: `"./lib/python"` |
| `sql_s3_prefix` | `string` | Prefixo S3 para os arquivos SQL | Default: `"sql/"` |
| `python_s3_prefix` | `string` | Prefixo S3 para os arquivos Python | Default: `"lib/python/"` |
| `step_function_name` | `string` | Nome da State Machine | Default: `"orchestrator"` |
| `log_retention_days` | `number` | Retenção do Log Group em dias | Default: `30` |
| `schedule_expression` | `string` | Cron de fallback | Default: `"cron(0 6 * * ? *)"` |

### Módulo `bootstrap`

| Variável | Tipo | Descrição | Obrigatória |
|---|---|---|---|
| `state_bucket_name` | `string` | Nome do bucket S3 para Terraform state | Sim |
| `environment` | `string` | Ambiente (`dev`/`prod`) | Sim |
| `common_tags` | `map(string)` | Mapa de tags obrigatórias | Sim |

**Outputs:**

| Output | Descrição |
|---|---|
| `state_bucket_arn` | ARN do bucket de state |
| `state_bucket_name` | Nome do bucket de state |

### Módulo `step-function`

| Variável | Tipo | Descrição | Obrigatória |
|---|---|---|---|
| `name` | `string` | Nome da State Machine | Sim |
| `environment` | `string` | Ambiente (`dev`/`prod`) | Sim |
| `step_function_role_arn` | `string` | ARN da execution role existente na conta | Sim |
| `glue_database_name` | `string` | Database Glue da tabela monitorada | Sim |
| `glue_table_name` | `string` | Tabela Glue a monitorar via EventBridge | Sim |
| `log_retention_days` | `number` | Retenção do Log Group em dias | Default: `30` |
| `schedule_expression` | `string` | Cron de fallback | Default: `"cron(0 6 * * ? *)"` |
| `common_tags` | `map(string)` | Mapa de tags obrigatórias | Sim |

**Outputs:**

| Output | Descrição |
|---|---|
| `state_machine_arn` | ARN da State Machine |
| `log_group_name` | Nome do CloudWatch Log Group |
| `eventbridge_rule_glue_arn` | ARN da rule de Glue CreatePartition |
| `eventbridge_rule_schedule_arn` | ARN da rule de schedule (cron fallback) |
| `eventbridge_invoke_role_arn` | ARN da role criada para o EventBridge invocar a SF |

### Módulo `s3-assets`

| Variável | Tipo | Descrição | Obrigatória |
|---|---|---|---|
| `bucket_name` | `string` | Nome do bucket de assets | Sim |
| `environment` | `string` | Ambiente (`dev`/`prod`) | Sim |
| `sql_assets_path` | `string` | Path local dos arquivos SQL | Sim |
| `python_assets_path` | `string` | Path local dos arquivos Python | Sim |
| `sql_s3_prefix` | `string` | Prefixo S3 para arquivos SQL | Default: `"sql/"` |
| `python_s3_prefix` | `string` | Prefixo S3 para arquivos Python | Default: `"lib/python/"` |
| `versioning_enabled` | `bool` | Habilita versionamento S3 | Default: `true` |
| `lifecycle_transition_days` | `number` | Dias para transição para S3-IA | Default: `90` |
| `common_tags` | `map(string)` | Mapa de tags obrigatórias | Sim |

**Outputs:**

| Output | Descrição |
|---|---|
| `bucket_arn` | ARN do bucket de assets |
| `bucket_name` | Nome do bucket de assets |

---

## 3. Event Pattern EventBridge (Glue Catalog)

### Event Pattern — Trigger por CreatePartition

```json
{
  "source": ["aws.glue"],
  "detail-type": ["Glue Data Catalog Table State Change"],
  "detail": {
    "databaseName": ["${glue_database_name}"],
    "tableName": ["${glue_table_name}"],
    "typeOfChange": ["CreatePartition", "BatchCreatePartition"]
  }
}
```

**Notas:**
- `BatchCreatePartition` incluído — pipelines de backfill criam partições em lote; omiti-lo causaria triggers perdidos.
- Eventos do Glue Catalog são best-effort: sem garantia de entrega. Cron de fallback mitiga esse risco.
- Implementar no Terraform via `jsonencode()` com interpolação das variáveis.

### Schedule de Fallback (cron diário às 06:00 UTC)

```
cron(0 6 * * ? *)
```

Passado via variável `schedule_expression` com default `"cron(0 6 * * ? *)"` — sobrescritável por ambiente.

---

## 4. Diagrama Lógico do Fluxo

### Fluxo Principal: Trigger por Partição Nova no Glue Catalog

```
┌─────────────────────────────────────────────────────────────────┐
│  AWS Glue Data Catalog                                          │
│  Operação: CreatePartition / BatchCreatePartition               │
│  Database: var.glue_database_name                               │
│  Table:    var.glue_table_name                                  │
└───────────────────────┬─────────────────────────────────────────┘
                        │ Emite evento automático
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│  Amazon EventBridge — Default Event Bus                         │
│  Rule: {project}-{env}-glue-partition-created                   │
│  Pattern: source=aws.glue, typeOfChange=CreatePartition         │
└───────────────────────┬─────────────────────────────────────────┘
                        │ Target: Step Functions StartExecution
                        │ Role: {project}-{env}-eb-invoke-sf
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│  AWS Step Functions — State Machine (Standard)                  │
│  Execution Role: var.step_function_role_arn (pré-existente)     │
│  Logs: CloudWatch /aws/states/{project}-{env}-{name}            │
│                                                                 │
│  [Estado 1: Placeholder — Pass]                                 │
│       │                                                         │
│       ▼                                                         │
│  [Estado 2: Placeholder — Pass]                                 │
│       │                                                         │
│       ▼                                                         │
│  [Sucesso]                                                      │
└─────────────────────────────────────────────────────────────────┘
```

### Fluxo Alternativo: Fallback Agendado (Cron)

```
┌─────────────────────────────────────────────────────────────────┐
│  Amazon EventBridge — Scheduled Rule                            │
│  Rule: {project}-{env}-daily-fallback                           │
│  Schedule: cron(0 6 * * ? *)  →  diariamente às 06:00 UTC      │
└───────────────────────┬─────────────────────────────────────────┘
                        │ Target: Step Functions StartExecution
                        │ Role: {project}-{env}-eb-invoke-sf (mesma)
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│  AWS Step Functions — State Machine (Standard)                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Decisão de Design: ASL Inline vs Arquivo Local vs S3

### Comparativo

| Critério | ASL inline (`jsonencode`) | Arquivo local (`templatefile`) | Upload para S3 |
|---|---|---|---|
| Versionamento em Git | Sim, mas ilegível | Sim, arquivo dedicado legível | Indireto |
| Legibilidade | Baixa | Alta | Alta |
| Dependência de bootstrap | Nenhuma | Nenhuma | Requer bucket S3 criado antes |
| Diff no `terraform plan` | Verboso | Limpo | Invisível (opaque) |
| Suporte a variáveis Terraform | Via `jsonencode()` | Via `templatefile()` | Não |

### Decisão: Arquivo local via `templatefile()`

```hcl
definition = templatefile("${path.module}/asl/state_machine.json", {
  # variáveis interpoladas no ASL (ex: ARNs de targets futuros)
})
```

**Justificativa:**
1. ASL em arquivo dedicado — editável com syntax highlighting de JSON.
2. Sem dependência de ordem de criação: módulo `step-function` funciona isoladamente.
3. `terraform plan` mostra diff completo da state machine.
4. `templatefile()` interpola ARNs e nomes no ASL sem concatenação manual.
5. Upload para S3 justificado apenas se ASL exceder o limite da API (1 MB) — improvável.

---

## 6. Tags Obrigatórias

### Tags requeridas

| Tag | Exemplo DEV | Exemplo PROD | Fonte |
|---|---|---|---|
| `Project` | `"data-platform"` | `"data-platform"` | `var.project` |
| `Environment` | `"dev"` | `"prod"` | `var.environment` |
| `ManagedBy` | `"terraform"` | `"terraform"` | hardcoded em `locals` |
| `Owner` | `"data-team"` | `"data-team"` | `var.owner` |
| `CostCenter` | `"eng-001"` | `"eng-001"` | `var.cost_center` |

### Implementação em `locals.tf` (root module)

```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
}
```

### Convenção de nomenclatura

Padrão: `${var.project}-${var.environment}-<recurso>`

Exemplos:
- State Machine: `data-platform-dev-orchestrator`
- Log Group: `/aws/states/data-platform-dev-orchestrator`
- S3 bucket assets: `data-platform-dev-assets-<account_id>` (sufixo account ID para unicidade global)
- EventBridge rules: `data-platform-dev-glue-partition-created`, `data-platform-dev-daily-fallback`
- IAM role EventBridge: `data-platform-dev-eb-invoke-sf`

`account_id` obtido via `data "aws_caller_identity" "current" {}` no root module.

---

## Riscos e Pontos de Atenção

| Risco | Impacto | Mitigação |
|---|---|---|
| Eventos Glue Catalog são best-effort | Trigger pode não disparar | Cron fallback diário às 06:00 UTC |
| Bucket S3 com nome global único | Colisão de nomes entre contas | Sufixar com `account_id` |
| EventBridge invoke role com permissão excessiva | Risco de segurança | `Resource` restrito ao ARN exato da SF, não `*` |
| Step Functions Standard: cobrança por transição | Custo proporcional ao número de estados | Express para workloads de alto volume futuro |

# ===========================================================================
# AMBIENTE: dev
# Uso: terraform plan -var-file="environments/dev.tfvars"
# ATENCAO: este arquivo contém valores sensíveis — NÃO commitar com valores reais.
# ===========================================================================

# ---------------------------------------------------------------------------
# REQUIRED — preencher antes do primeiro deploy
# ---------------------------------------------------------------------------

environment = "dev"      # fixo para este arquivo

project     = "FILL_ME"  # ex: "meu-projeto"
owner       = "FILL_ME"  # ex: "squad-dados"
cost_center = "FILL_ME"  # ex: "CC-1234" — código de billing

# ARN da IAM role que o Step Functions usará para executar
# sensitive — não commitar valor real; prefira injetar via CI/CD secret
step_function_role_arn = "FILL_ME"  # ex: "arn:aws:iam::123456789012:role/sf-execution-role"

# Nome base do bucket S3 de assets (account_id é concatenado pelos locals do módulo)
assets_bucket_name = "FILL_ME"  # ex: "meu-projeto-assets"

# Bucket do Terraform remote state (deve existir previamente)
state_bucket_name = "FILL_ME"  # ex: "meu-projeto-terraform-state"

# Emails de contato do squad
owner_team_email = "FILL_ME"  # ex: "squad-dados@empresa.com"
tech_team_email  = "FILL_ME"  # ex: "engenharia-dados@empresa.com"

# ---------------------------------------------------------------------------
# OPCIONAIS — defaults do variables.tf já aplicados; ajustar se necessário
# ---------------------------------------------------------------------------

aws_region = "us-east-1"  # região AWS de deploy

sql_s3_prefix    = "sql/"         # prefixo no S3 para arquivos SQL
python_s3_prefix = "lib/python/"  # prefixo no S3 para libs Python

# Alias de deployment — útil para ambientes efêmeros (ex: PR branches)
# Deixar null para usar apenas environment como sufixo
deployment_alias = null

# Tags de rastreabilidade do repositório GitHub (substituídas pela CI/CD)
github_repo_id   = "GITHUB_REPOSITORY_TAG_PLACEHOLDER"
github_repo_name = "GITHUB_REPOSITORY_TAG_PLACEHOLDER"

# Flags de reprocessamento para as State Machines
reprocessamento        = "true"  # habilita reprocessamento de partições
range_reprocessamento  = "7"     # janela em dias para reprocessamento
defasagem              = "1"     # dias de defasagem aceitável antes de alertar

# ---------------------------------------------------------------------------
# ASL template variables — preencher com os nomes dos recursos Glue/S3
# Deixar "" para variáveis não utilizadas neste pipeline
# ---------------------------------------------------------------------------

bucket      = ""  # ex: "meu-bucket-datalake" — S3 bucket do pipeline
glue_db     = ""  # ex: "db_raw" — Glue database de origem

pipeline_1_table = ""  # ex: "tb_eventos_raw"
pipeline_2_table = ""  # ex: "tb_eventos_trusted"

glue_main_job_name     = ""  # ex: "job-ingestao-principal"
glue_heimdall_job_name = ""  # ex: "job-heimdall-dq"
glue_hermes_job_name   = ""  # ex: "job-hermes-delivery"
glue_repair_job_name   = ""  # ex: "job-repair-iceberg"

region_name    = ""  # ex: "us-east-1" — região dos recursos Glue
partition_name = ""  # ex: "dt" — nome da coluna de partição
partition_type = ""  # ex: "date" — tipo da partição (date, string, etc.)

owner_email = ""  # ex: "squad-dados@empresa.com" — email para alertas da ASL
members     = ""  # ex: "user1@empresa.com,user2@empresa.com" — membros adicionais
group_name  = ""  # ex: "squad-dados" — grupo de notificação

ignore_partitions_tb_name = ""  # ex: "tb_ignore_partitions" — tabela de controle de partições ignoradas

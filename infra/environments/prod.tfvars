# ===========================================================================
# AMBIENTE: prod
# Uso: terraform plan -var-file="environments/prod.tfvars"
# ATENCAO: este arquivo contém valores sensíveis — NÃO commitar com valores reais.
# ===========================================================================

# ---------------------------------------------------------------------------
# REQUIRED — preencher antes do primeiro deploy
# ---------------------------------------------------------------------------

environment = "prod" # fixo para este arquivo

project     = "FILL_ME" # ex: "meu-projeto"
owner       = "FILL_ME" # ex: "squad-dados"
cost_center = "FILL_ME" # ex: "CC-1234" — código de billing

# ARN da IAM role que o Step Functions usará para executar
# sensitive — não commitar valor real; prefira injetar via CI/CD secret
step_function_role_arn = "FILL_ME" # ex: "arn:aws:iam::123456789012:role/sf-execution-role"

# Nome base do bucket S3 de assets (account_id é concatenado pelos locals do módulo)
assets_bucket_name = "FILL_ME" # ex: "meu-projeto-assets"

# Bucket do Terraform remote state (deve existir previamente)
state_bucket_name = "FILL_ME" # ex: "meu-projeto-terraform-state"

# Emails de contato do squad
owner_team_email = "FILL_ME" # ex: "squad-dados@empresa.com"
tech_team_email  = "FILL_ME" # ex: "engenharia-dados@empresa.com"

# AZ usada pela connection compartilhada do Glue
availability_zone = "FILL_ME" # ex: "us-east-1a"

# Nome do repositório/projeto — compõe o path S3 dos scripts dos jobs Glue
# (s3://<glue_source_bucket>/<repository_name>/src/<script_file>)
repository_name = "FILL_ME" # ex: "aws-infra"

# ---------------------------------------------------------------------------
# OPCIONAIS — defaults do variables.tf já aplicados; ajustar se necessário
# ---------------------------------------------------------------------------

aws_region = "us-east-1" # região AWS de deploy

sql_s3_prefix    = "sql/"        # prefixo no S3 para arquivos SQL
python_s3_prefix = "lib/python/" # prefixo no S3 para libs Python

# Alias de deployment — útil para ambientes efêmeros (ex: PR branches)
# Deixar null para usar apenas environment como sufixo
deployment_alias = null

# Tags de rastreabilidade do repositório GitHub (substituídas pela CI/CD)
github_repo_id   = "GITHUB_REPOSITORY_TAG_PLACEHOLDER"
github_repo_name = "GITHUB_REPOSITORY_TAG_PLACEHOLDER"

# Flags de reprocessamento para as State Machines
reprocessamento       = "true" # habilita reprocessamento de partições
range_reprocessamento = "7"    # janela em dias para reprocessamento
defasagem             = "1"    # dias de defasagem aceitável antes de alertar

# ---------------------------------------------------------------------------
# ASL template variables — preencher com os nomes dos recursos Glue/S3
# Deixar "" para variáveis não utilizadas neste pipeline
# ---------------------------------------------------------------------------

bucket  = "" # ex: "meu-bucket-datalake" — S3 bucket do pipeline
glue_db = "" # ex: "db_raw" — Glue database de origem

pipeline_1_table = "" # ex: "tb_eventos_raw"
pipeline_2_table = "" # ex: "tb_eventos_trusted"

region_name    = "" # ex: "us-east-1" — região dos recursos Glue
partition_name = "" # ex: "dt" — nome da coluna de partição
partition_type = "" # ex: "date" — tipo da partição (date, string, etc.)

owner_email = "" # ex: "squad-dados@empresa.com" — email para alertas da ASL
members     = "" # ex: "user1@empresa.com,user2@empresa.com" — membros adicionais
group_name  = "" # ex: "squad-dados" — grupo de notificação

ignore_partitions_tb_name = "" # ex: "tb_ignore_partitions" — tabela de controle de partições ignoradas

# ---------------------------------------------------------------------------
# Buckets usados pelos jobs Glue (deixar "" para usar o default composto a
# partir de name_prefix em locals.tf, ex: "FILL_ME-prod-glue-source")
# ---------------------------------------------------------------------------

glue_source_bucket_name = "" # ex: "meu-projeto-prod-glue-source"
glue_stage_bucket_name  = "" # ex: "meu-projeto-prod-glue-stage"
glue_backup_bucket_name = "" # ex: "meu-projeto-prod-glue-backup"
glue_target_bucket_name = "" # ex: "meu-projeto-prod-glue-target"
athena_output_bucket    = "" # ex: "meu-projeto-prod-athena-results"

# ---------------------------------------------------------------------------
# Glue jobs — auto-discovery: cada chave corresponde a um arquivo .py em
# app/src/ (script_file). O nome real do job AWS vem sempre de glue_job_name,
# nunca da chave do map. Valores abaixo são de EXEMPLO — revisar dimensionamento
# de workers/timeout antes do primeiro deploy real em prod.
# ---------------------------------------------------------------------------

glue_jobs = {
  main = {
    glue_job_name              = "Yggdra"
    script_file                = "main.py"
    glue_job_description       = "Job principal de orquestração Yggdra"
    source_database            = "workspace_db"
    source_table               = "sepj_sot_ga4_perfis_operadores"
    conversion_mode            = "MERGE"
    save_method                = "OVERWRITE"
    workgroup                  = "primary"
    glue_job_worker_type       = "G.1X"
    glue_job_number_of_workers = 4
    glue_job_timeout           = 120
    glue_job_max_retries       = 1
  }

  heimdall = {
    glue_job_name              = "YGGDRA - Heimdall"
    script_file                = "heimdall.py"
    glue_job_description       = "Job de data quality/monitoramento Heimdall"
    source_database            = "workspace_db"
    source_table               = "sepj_sot_ga4_perfis_operadores"
    conversion_mode            = "INSERT_INTO"
    save_method                = "APPEND"
    workgroup                  = "primary"
    glue_job_worker_type       = "G.1X"
    glue_job_number_of_workers = 2
    glue_job_timeout           = 60
    glue_job_max_retries       = 1
  }

  hermes = {
    glue_job_name              = "Yggdra_Hermes"
    script_file                = "hermes.py"
    glue_job_description       = "Job de entrega/delivery Hermes"
    source_database            = "workspace_db"
    source_table               = "sepj_spec_ga4_perfis_operadores_analitica"
    conversion_mode            = "INSERT_INTO"
    save_method                = "APPEND"
    workgroup                  = "primary"
    glue_job_worker_type       = "G.1X"
    glue_job_number_of_workers = 2
    glue_job_timeout           = 60
    glue_job_max_retries       = 1
  }

  repair_table_perfis_operadores_iam = {
    glue_job_name              = "repair_table_perfis_operadores_iam"
    script_file                = "repair_table_perfis_operadores_iam.py"
    glue_job_description       = "Job de manutenção/repair de partições Iceberg"
    source_database            = "workspace_db"
    source_table               = "sepj_sot_ga4_perfis_operadores"
    conversion_mode            = "OVERWRITE"
    save_method                = "OVERWRITE"
    workgroup                  = "primary"
    glue_job_worker_type       = "G.1X"
    glue_job_number_of_workers = 2
    glue_job_timeout           = 60
    glue_job_max_retries       = 1
  }
}

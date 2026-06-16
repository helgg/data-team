variable "aws_region" {
  description = "região AWS dos recursos"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "ambiente de deploy (dev ou prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be 'dev' or 'prod'."
  }
}

variable "project" {
  description = "nome do projeto (prefixo dos recursos)"
  type        = string
}

variable "owner" {
  description = "squad responsável pelos recursos"
  type        = string
}

variable "cost_center" {
  description = "centro de custo"
  type        = string
}

variable "step_function_role_arn" {
  description = "ARN da role IAM de execução do Step Functions"
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Variáveis globais do template ASL
# ---------------------------------------------------------------------------

variable "bucket" {
  description = "bucket S3 principal (data lake)"
  type        = string
  default     = ""
}

variable "glue_db" {
  description = "database Glue"
  type        = string
  default     = ""
}

variable "pipeline_1_table" {
  description = "tabela Glue do pipeline 1"
  type        = string
  default     = ""
}

variable "pipeline_2_table" {
  description = "tabela Glue do pipeline 2"
  type        = string
  default     = ""
}

variable "glue_main_job_name" {
  description = "job Glue principal"
  type        = string
  default     = ""
}

variable "glue_heimdall_job_name" {
  description = "job Glue Heimdall"
  type        = string
  default     = ""
}

variable "glue_hermes_job_name" {
  description = "job Glue Hermes"
  type        = string
  default     = ""
}

variable "glue_repair_job_name" {
  description = "job Glue de repair"
  type        = string
  default     = ""
}

variable "region_name" {
  description = "nome da região AWS"
  type        = string
  default     = ""
}

variable "partition_name" {
  description = "coluna de partição"
  type        = string
  default     = ""
}

variable "partition_type" {
  description = "tipo de partição"
  type        = string
  default     = ""
}

variable "owner_email" {
  description = "email do owner do pipeline"
  type        = string
  default     = ""
}

variable "members" {
  description = "emails do time (separados por vírgula)"
  type        = string
  default     = ""
}

variable "group_name" {
  description = "nome do grupo/squad"
  type        = string
  default     = ""
}

variable "reprocessamento" {
  description = "habilita reprocessamento"
  type        = string
  default     = "true"
}

variable "range_reprocessamento" {
  description = "janela de reprocessamento (dias)"
  type        = string
  default     = "7"
}

variable "defasagem" {
  description = "defasagem em dias"
  type        = string
  default     = "1"
}

variable "ignore_partitions_tb_name" {
  description = "tabela de partições a ignorar"
  type        = string
  default     = ""
}

variable "assets_bucket_name" {
  description = "nome base do bucket de assets"
  type        = string
}

variable "state_bucket_name" {
  description = "bucket do estado Terraform"
  type        = string
}

variable "sql_s3_prefix" {
  description = "prefixo S3 para arquivos SQL"
  type        = string
  default     = "sql/"
}

variable "python_s3_prefix" {
  description = "prefixo S3 para arquivos Python"
  type        = string
  default     = "python/"
}

variable "deployment_alias" {
  description = "alias do Step Functions (null = sem alias)"
  type        = string
  default     = null
}

variable "owner_team_email" {
  description = "email do time owner"
  type        = string
}

variable "tech_team_email" {
  description = "email do time técnico"
  type        = string
}

variable "github_repo_id" {
  description = "ID do repositório GitHub (tag)"
  type        = string
  default     = "GITHUB_REPOSITORY_TAG_PLACEHOLDER"
}

variable "github_repo_name" {
  description = "nome do repositório GitHub (tag)"
  type        = string
  default     = "GITHUB_REPOSITORY_TAG_PLACEHOLDER"
}

variable "s3_common_prefix" {
  description = "prefixo S3 comum para assets (deve terminar com /)"
  type        = string
  default     = "assets/"
}

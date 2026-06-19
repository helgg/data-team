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

# ---------------------------------------------------------------------------
# Glue jobs — auto-discovery via app/src/*.py (ver locals.tf e main.tf)
# ---------------------------------------------------------------------------

variable "glue_jobs" {
  description = "configuração dos jobs Glue, chaveada pelo nome lógico (normalmente igual ao nome do arquivo .py em app/src/, sem extensão). O nome real do job AWS vem sempre do campo glue_job_name, nunca da chave do map. Os nomes dos campos espelham os argumentos do módulo remoto itau-cw5-modules-glue//modules/glue_job (ref v0.0.2)."
  type = map(object({
    glue_job_name                = string
    script_file                  = string # arquivo .py em app/src/, ex: "main.py"
    glue_job_description         = optional(string, "")
    source_database              = string
    source_table                 = string
    conversion_mode              = string
    save_method                  = string # mapeado para o argumento real "--save_mothod" (typo do contrato original, preservado)
    columns_list                 = optional(string, "")
    partition_columns            = optional(string, "")
    sample_size                  = optional(string, "")
    workgroup                    = string
    glue_job_glue_version        = optional(string, "4.0")
    glue_job_max_retries         = optional(number, 0)
    glue_job_timeout             = optional(number, 60)
    glue_job_worker_type         = string
    glue_job_number_of_workers   = number
    glue_job_execution_class     = optional(string) # null = usa var.glue_job_execution_class
    glue_job_run_queuing_enabled = optional(bool)   # null = usa var.glue_job_run_queuing_enabled
    enable_glue_job              = optional(bool)   # null = usa var.enable_glue_job
    extra_arguments              = optional(map(string), {})
    tags                         = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.glue_jobs : contains(["CTAS", "INSERT_INTO", "MERGE", "OVERWRITE"], v.conversion_mode)])
    error_message = "conversion_mode deve ser um dos valores suportados pelo módulo glue_job: CTAS, INSERT_INTO, MERGE ou OVERWRITE."
  }
}

variable "glue_source_bucket_name" {
  description = "nome base do bucket S3 de origem (source) usado pelos jobs Glue"
  type        = string
  default     = ""
}

variable "glue_stage_bucket_name" {
  description = "nome base do bucket S3 de stage (intermediário) usado pelos jobs Glue"
  type        = string
  default     = ""
}

variable "glue_backup_bucket_name" {
  description = "nome base do bucket S3 de backup usado pelos jobs Glue"
  type        = string
  default     = ""
}

variable "glue_target_bucket_name" {
  description = "nome base do bucket S3 de destino (target) usado pelos jobs Glue"
  type        = string
  default     = ""
}

variable "athena_output_bucket" {
  description = "nome base do bucket S3 de resultados de queries Athena"
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Glue — KMS security configuration e connection (recursos compartilhados)
# ---------------------------------------------------------------------------

variable "enable_kms_key" {
  description = "habilita a criação da chave KMS compartilhada dos jobs Glue"
  type        = bool
  default     = true
}

variable "deletion_window_in_days" {
  description = "janela de deleção da chave KMS (dias)"
  type        = number
  default     = 30
}

variable "enable_key_rotation" {
  description = "habilita rotação automática da chave KMS"
  type        = bool
  default     = true
}

variable "enable_kms_alias" {
  description = "habilita a criação de alias para a chave KMS"
  type        = bool
  default     = true
}

variable "key_alias" {
  description = "alias da chave KMS (default: alias/<name_prefix>-glue se vazio)"
  type        = string
  default     = ""
}

variable "enable_glue_security_configuration" {
  description = "habilita a security configuration compartilhada do Glue"
  type        = bool
  default     = true
}

variable "glue_security_configuration_name" {
  description = "nome da security configuration do Glue (default composto via name_prefix se vazio)"
  type        = string
  default     = ""
}

variable "enable_glue_connection" {
  description = "habilita a connection do Glue compartilhada entre todos os jobs"
  type        = bool
  default     = true
}

variable "glue_connection_name" {
  description = "nome da connection do Glue (default composto via name_prefix se vazio)"
  type        = string
  default     = ""
}

variable "glue_connection_description" {
  description = "descrição da connection do Glue"
  type        = string
  default     = "Conexão Glue compartilhada entre os jobs do pipeline"
}

variable "glue_connection_connection_type" {
  description = "tipo da connection do Glue (ex: NETWORK, JDBC)"
  type        = string
  default     = "NETWORK"
}

variable "availability_zone" {
  description = "availability zone usada pela connection do Glue"
  type        = string
}

# ---------------------------------------------------------------------------
# Glue — defaults globais dos jobs (podem ser sobrescritos por job em glue_jobs)
# ---------------------------------------------------------------------------

variable "enable_glue_job" {
  description = "habilita os jobs Glue por padrão (sobrescrito por job via glue_jobs[].enable_glue_job)"
  type        = bool
  default     = true
}

variable "glue_job_execution_class" {
  description = "classe de execução padrão dos jobs Glue (STANDARD ou FLEX)"
  type        = string
  default     = "STANDARD"
}

variable "glue_job_run_queuing_enabled" {
  description = "habilita enfileiramento de execuções por padrão para os jobs Glue"
  type        = bool
  default     = false
}

variable "repository_name" {
  description = "nome do repositório/projeto, usado para compor o path S3 dos scripts dos jobs Glue"
  type        = string
}

variable "enable_extra_py_files" {
  description = "habilita o input extra-py-files (utils.zip) nos jobs Glue — manter false até o utils.zip existir no repositório"
  type        = bool
  default     = false
}

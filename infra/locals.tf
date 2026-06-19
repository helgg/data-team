locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }

  assets_bucket_name = "${var.assets_bucket_name}-${data.aws_caller_identity.current.account_id}"

  # Nomes de bucket dos jobs Glue — compostos a partir do name_prefix quando a
  # variável correspondente não for explicitamente preenchida via tfvars.
  glue_source_bucket_name = var.glue_source_bucket_name != "" ? var.glue_source_bucket_name : "${local.name_prefix}-glue-source"
  glue_stage_bucket_name  = var.glue_stage_bucket_name != "" ? var.glue_stage_bucket_name : "${local.name_prefix}-glue-stage"
  glue_backup_bucket_name = var.glue_backup_bucket_name != "" ? var.glue_backup_bucket_name : "${local.name_prefix}-glue-backup"
  glue_target_bucket_name = var.glue_target_bucket_name != "" ? var.glue_target_bucket_name : "${local.name_prefix}-glue-target"
  athena_output_bucket    = var.athena_output_bucket != "" ? var.athena_output_bucket : "${local.name_prefix}-athena-results"

  # Recursos Glue compartilhados (KMS, security configuration, connection) —
  # nomes compostos a partir do name_prefix quando não preenchidos via tfvars.
  glue_kms_alias                   = var.key_alias != "" ? var.key_alias : "alias/${local.name_prefix}-glue"
  glue_security_configuration_name = var.glue_security_configuration_name != "" ? var.glue_security_configuration_name : "${local.name_prefix}-glue-security-config"
  glue_connection_name             = var.glue_connection_name != "" ? var.glue_connection_name : "${local.name_prefix}-glue-connection"

  # Auto-discovery: todo *.py em app/src/ (fora de infra/, na raiz do repo)
  # vira uma entrada candidata de job Glue. O map final de jobs efetivamente
  # criados continua sendo var.glue_jobs (script_file referencia o arquivo);
  # este local serve apenas para validar/discovery e está disponível para uso
  # futuro (ex: detectar arquivos órfãos sem entrada em var.glue_jobs).
  glue_script_files = fileset("${path.root}/../app/src", "*.py")

  # Auto-discovery: todo *.json em stepfunctions/ vira uma state machine
  stepfunction_files = fileset("${path.module}/stepfunctions", "*.json")
  stepfunctions      = { for f in local.stepfunction_files : trimsuffix(f, ".json") => f }

  # Auto-discovery: todo *.json em trigger/ vira uma regra EventBridge
  trigger_files = fileset("${path.module}/trigger", "*.json")
  triggers      = { for f in local.trigger_files : trimsuffix(f, ".json") => jsondecode(file("${path.module}/trigger/${f}")) }

  # Variáveis globais injetadas em cada templatefile()
  asl_vars = {
    account_id                = data.aws_caller_identity.current.account_id
    bucket                    = var.bucket
    glue_db                   = var.glue_db
    pipeline_1_table          = var.pipeline_1_table
    pipeline_2_table          = var.pipeline_2_table
    glue_main_job_name        = module.glue_jobs["main"].glue_job_name
    glue_heimdall_job_name    = module.glue_jobs["heimdall"].glue_job_name
    glue_hermes_job_name      = module.glue_jobs["hermes"].glue_job_name
    glue_repair_job_name      = module.glue_jobs["repair_table_perfis_operadores_iam"].glue_job_name
    region_name               = var.region_name
    partition_name            = var.partition_name
    partition_type            = var.partition_type
    owner_email               = var.owner_email
    members                   = var.members
    group_name                = var.group_name
    reprocessamento           = var.reprocessamento
    range_reprocessamento     = var.range_reprocessamento
    defasagem                 = var.defasagem
    ignore_partitions_tb_name = var.ignore_partitions_tb_name
  }
}

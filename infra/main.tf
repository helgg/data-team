module "state_machine" {
  source   = "./modules/stepfunctions"
  for_each = local.stepfunctions

  state_machine_name         = "${local.name_prefix}-${each.key}"
  state_machine_iam_role_arn = var.step_function_role_arn
  state_machine_log_level    = var.environment == "prod" ? "ERROR" : "ALL"
  state_machine_type         = "STANDARD"
  state_machine_definition   = templatefile("${path.module}/stepfunctions/${each.key}.json", local.asl_vars)
  owner_team_email           = var.owner_team_email
  tech_team_email            = var.tech_team_email
  github_repo_id             = var.github_repo_id
  github_repo_name           = var.github_repo_name
  deployment_alias           = var.deployment_alias
  tags                       = local.common_tags
}

module "s3_assets" {
  source = "./modules/s3-assets"

  bucket_name        = local.assets_bucket_name
  environment        = var.environment
  sql_assets_path    = "${path.root}/sql-scripts"
  python_assets_path = "${path.root}/../app/src"
  s3_common_prefix   = var.s3_common_prefix
  sql_s3_prefix      = var.sql_s3_prefix
  python_s3_prefix   = var.python_s3_prefix
  common_tags        = local.common_tags
}

# -----------------------------------------------------------------------------
# Glue — recursos compartilhados (singleton): KMS security configuration e
# connection, usados por todos os jobs gerados via auto-discovery abaixo.
# Contrato confirmado a partir de referência real do módulo (mesmo ref
# v0.0.2 usado em projeto já existente no banco).
# -----------------------------------------------------------------------------
module "glue_security_configuration" {
  source = "git::https://github.com/itau-corp/itau-cw5-modules-glue.git//modules/glue_security_configuration?ref=v0.0.2"

  enable_kms_key          = var.enable_kms_key
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  policy                  = data.aws_iam_policy_document.kms_policy.json
  tags                    = merge(local.common_tags, { kms_data_classification = "Internal" })

  enable_kms_alias = var.enable_kms_alias
  alias            = local.glue_kms_alias

  enable_glue_security_configuration = var.enable_glue_security_configuration
  glue_security_configuration_name   = local.glue_security_configuration_name

  glue_security_configuration_encryption_configuration = {
    cloudwatch_encryption = [{
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn                = module.glue_security_configuration.key_arn
    }]
    job_bookmarks_encryption = [{
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn                   = module.glue_security_configuration.key_arn
    }]
    s3_encryption = [{
      s3_encryption_mode = "SSE-KMS"
      kms_key_arn        = module.glue_security_configuration.key_arn
    }]
  }
}

module "glue_connection" {
  source = "git::https://github.com/itau-corp/itau-cw5-modules-glue.git//modules/glue_connection?ref=v0.0.2"

  enable_glue_connection          = var.enable_glue_connection
  glue_connection_name            = local.glue_connection_name
  glue_connection_description     = var.glue_connection_description
  glue_connection_connection_type = var.glue_connection_connection_type
  availability_zone               = var.availability_zone
}

# -----------------------------------------------------------------------------
# Glue jobs — auto-discovery: cada entrada de var.glue_jobs vira um job Glue.
# O script .py correspondente (each.value.script_file) já é publicado no S3
# pelo module.s3_assets acima (fileset sobre app/src/**/*.py). O nome do job
# AWS vem sempre do campo glue_job_name (nunca da chave do map).
#
# Único desvio intencional em relação à referência original (que tinha 1 job
# fixo apontando para "src/main.py"): aqui script_location usa
# each.value.script_file, permitindo 1 job por arquivo .py. O argumento
# "--save_mothod" mantém o typo do contrato real do módulo (não é erro nosso).
# -----------------------------------------------------------------------------
module "glue_jobs" {
  source   = "git::https://github.com/itau-corp/itau-cw5-modules-glue.git//modules/glue_job?ref=v0.0.2"
  for_each = var.glue_jobs

  enable_glue_job                 = coalesce(each.value.enable_glue_job, var.enable_glue_job)
  glue_job_name                   = each.value.glue_job_name
  glue_job_role_arn               = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/iamsr/role-glue-exec"
  glue_job_description            = each.value.glue_job_description
  glue_job_connections            = [module.glue_connection.glue_connection_name]
  glue_job_glue_version           = each.value.glue_job_glue_version
  glue_job_max_retries            = each.value.glue_job_max_retries
  glue_job_timeout                = each.value.glue_job_timeout
  glue_job_security_configuration = module.glue_security_configuration.glue_security_configuration_name
  glue_job_worker_type            = each.value.glue_job_worker_type
  glue_job_number_of_workers      = each.value.glue_job_number_of_workers
  glue_source_bucket_name         = local.glue_source_bucket_name
  glue_job_execution_class        = coalesce(each.value.glue_job_execution_class, var.glue_job_execution_class)
  glue_job_run_queuing_enabled    = coalesce(each.value.glue_job_run_queuing_enabled, var.glue_job_run_queuing_enabled)
  repository_name                 = var.repository_name
  enable_extra_py_files           = var.enable_extra_py_files

  glue_job_default_arguments = merge({
    "--job-language"                     = "python"
    "--JOB_NAME"                         = each.value.glue_job_name
    "--source_database"                  = each.value.source_database
    "--source_table"                     = each.value.source_table
    "--stage_path_s3"                    = "s3://${local.glue_stage_bucket_name}/${each.value.source_table}_STAGE/"
    "--backup_path_s3"                   = "s3://${local.glue_backup_bucket_name}/${each.value.source_table}_BACKUP/"
    "--target_path_s3"                   = "s3://${local.glue_target_bucket_name}/${each.value.source_table}/"
    "--athena_output_bucket"             = "s3://${local.athena_output_bucket}/${each.value.source_table}_TEMP/"
    "--extra-py-files"                   = "s3://${local.glue_source_bucket_name}/${var.repository_name}/utils.zip"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--enable-spark-ui"                  = "true"
    "--continuous-log-logGroup"          = "true"
    "--enable-auto-scaling"              = "true"
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--enable-glue-datacatalog"          = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--log_level"                        = "info"
    "--conversion_mode"                  = each.value.conversion_mode
    "--save_mothod"                      = each.value.save_method
    "--columns_list"                     = each.value.columns_list
    "--partition_column"                 = each.value.partition_columns
    "--sample_size"                      = each.value.sample_size
    "--workgroup"                        = each.value.workgroup
    },
    each.value.extra_arguments
  )

  glue_job_command = [{
    script_location = "s3://${local.glue_source_bucket_name}/${var.repository_name}/src/${each.value.script_file}"
    python_version  = "3"
  }]

  tags = merge(local.common_tags, each.value.tags)

  depends_on = [module.glue_connection, module.glue_security_configuration]
}

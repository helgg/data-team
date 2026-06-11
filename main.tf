module "step_function" {
  source = "./modules/step-function"

  name                   = "${local.name_prefix}-${var.step_function_name}"
  environment            = var.environment
  step_function_role_arn = var.step_function_role_arn
  glue_database_name     = var.glue_database_name
  glue_table_name        = var.glue_table_name
  log_retention_days     = var.log_retention_days
  schedule_expression    = var.schedule_expression
  kms_key_arn            = var.kms_key_arn
  include_execution_data = var.include_execution_data
  log_level              = var.log_level
  enable_alarms          = var.enable_alarms
  alarm_sns_topic_arn    = var.alarm_sns_topic_arn
  common_tags            = local.common_tags
}

module "s3_assets" {
  source = "./modules/s3-assets"

  bucket_name         = local.assets_bucket_name
  environment         = var.environment
  sql_assets_path     = "${path.root}/sql"
  python_assets_path  = "${path.root}/lib/python"
  sql_s3_prefix       = var.sql_s3_prefix
  python_s3_prefix    = var.python_s3_prefix
  common_tags         = local.common_tags
}

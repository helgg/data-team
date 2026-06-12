module "step_function" {
  for_each = var.state_machines
  source   = "./modules/step-function"

  asl_file_path          = "${path.root}/asl/${each.key}.json"
  name                   = "${local.name_prefix}-${each.key}"
  environment            = var.environment
  step_function_role_arn = var.step_function_role_arn
  glue_database_name     = each.value.glue_database_name
  glue_table_name        = each.value.glue_table_name
  schedule_expression    = each.value.schedule_expression
  asl_template_vars      = each.value
  log_retention_days     = var.log_retention_days
  kms_key_arn            = var.kms_key_arn
  include_execution_data = var.include_execution_data
  log_level              = var.log_level
  enable_alarms          = var.enable_alarms
  alarm_sns_topic_arn    = var.alarm_sns_topic_arn
  common_tags            = local.common_tags
}

module "s3_assets" {
  source = "./modules/s3-assets"

  bucket_name        = local.assets_bucket_name
  environment        = var.environment
  sql_assets_path    = "${path.root}/sql"
  python_assets_path = "${path.root}/lib/python"
  sql_s3_prefix      = var.sql_s3_prefix
  python_s3_prefix   = var.python_s3_prefix
  common_tags        = local.common_tags
}

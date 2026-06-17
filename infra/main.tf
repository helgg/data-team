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
  python_assets_path = "${path.root}/python-lib"
  s3_common_prefix   = var.s3_common_prefix
  sql_s3_prefix      = var.sql_s3_prefix
  python_s3_prefix   = var.python_s3_prefix
  common_tags        = local.common_tags
}

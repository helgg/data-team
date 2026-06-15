module "state_machine" {
  source                      = "git::https://github.com/itau-corp/itau-ei3-modules-terraform-stepfunctions.git?ref=v2.3.1"
  for_each                    = local.stepfunctions
  state_machine_name          = each.key
  state_machine_iam_role_arn  = module.iamsr_module.roles[0].arn
  state_machine_log_level     = "ALL"
  state_machine_type          = "STANDARD"
  state_machine_definition    = templatefile("${path.module}/stepfunctions/${each.key}.json", local.interpolate_vars)
  owner_team_email            = "lilian.pracidelli@itau-unibanco.com.br"
  tech_team_email             = "bruno.pontes-lira@itau-unibanco.com.br"
  github_repo_id              = "GITHUB_REPOSITORY_TAG_PLACEHOLDER"
  github_repo_name            = "GITHUB_REPOSITORY_TAG_PLACEHOLDER"
  deployment_alias            = var.deployment_alias
  tags                        = local.tags
}
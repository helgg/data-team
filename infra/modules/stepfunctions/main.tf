locals {
  sfn_tags = merge(var.tags, {
    OwnerTeamEmail = var.owner_team_email
    TechTeamEmail  = var.tech_team_email
    GithubRepoId   = var.github_repo_id
    GithubRepoName = var.github_repo_name
  })
}

resource "aws_cloudwatch_log_group" "this" {
  # prefixo /aws/vendedlogs/states/ evita estourar o limite de resource policy do CloudWatch Logs para Step Functions
  name              = "/aws/vendedlogs/states/${var.state_machine_name}"
  retention_in_days = 30
  tags              = local.sfn_tags
}

resource "aws_sfn_state_machine" "this" {
  name       = var.state_machine_name
  role_arn   = var.state_machine_iam_role_arn
  type       = var.state_machine_type
  definition = var.state_machine_definition
  publish    = var.deployment_alias != null

  logging_configuration {
    level                  = var.state_machine_log_level
    include_execution_data = var.state_machine_log_level == "ALL"
    log_destination        = "${aws_cloudwatch_log_group.this.arn}:*"
  }

  tags = local.sfn_tags
}

resource "aws_sfn_alias" "this" {
  count = var.deployment_alias != null ? 1 : 0

  name = var.deployment_alias

  routing_configuration {
    state_machine_version_arn = aws_sfn_state_machine.this.state_machine_version_arn
    weight                    = 100
  }
}

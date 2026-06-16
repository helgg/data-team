variable "state_machine_name" {}
variable "state_machine_iam_role_arn" {}
variable "state_machine_log_level" {}
variable "state_machine_type" {}
variable "state_machine_definition" {}
variable "owner_team_email" {}
variable "tech_team_email" {}
variable "github_repo_id" {}
variable "github_repo_name" {}
variable "deployment_alias" { default = null }
variable "tags" { default = {} }

output "state_machine_arn" {
  value = "arn:aws:states:us-east-1:123456789012:stateMachine:${var.state_machine_name}"
}

output "state_machine_name" {
  value = var.state_machine_name
}

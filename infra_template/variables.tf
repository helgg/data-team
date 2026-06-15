variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be 'dev' or 'prod'."
  }
}

variable "project" {
  description = "Project name used as a prefix for all resource names"
  type        = string
}

variable "owner" {
  description = "Team or squad responsible for the resources"
  type        = string
}

variable "cost_center" {
  description = "Cost center identifier for billing allocation"
  type        = string
}

variable "step_function_role_arn" {
  description = "ARN of the pre-existing IAM execution role for Step Functions (shared across all state machines)"
  type        = string
  sensitive   = true
}

variable "state_machines" {
  description = "Map of state machines to create. Key must match the ASL filename: stepfunctions/<key>.json"
  type = map(object({
    glue_database_name  = string
    glue_table_name     = string
    s3_input_path       = optional(string, "")
    s3_output_path      = optional(string, "")
    schedule_expression = optional(string, "cron(0 6 * * ? *)")

    # ASL template variables — injected into templatefile() for orchestrator.json
    bucket                    = optional(string, "")
    glue_db                   = optional(string, "")
    pipeline_1_table          = optional(string, "")
    pipeline_2_table          = optional(string, "")
    glue_main_job_name        = optional(string, "")
    glue_heimdall_job_name    = optional(string, "")
    glue_hermes_job_name      = optional(string, "")
    glue_repair_job_name      = optional(string, "")
    region_name               = optional(string, "")
    partition_name            = optional(string, "")
    partition_type            = optional(string, "")
    owner_email               = optional(string, "")
    members                   = optional(string, "")
    group_name                = optional(string, "")
    reprocessamento           = optional(string, "true")
    range_reprocessamento     = optional(string, "7")
    defasagem                 = optional(string, "1")
    ignore_partitions_tb_name = optional(string, "")
  }))
}

variable "assets_bucket_name" {
  description = "Base name for the S3 assets bucket (SQL and Python files)"
  type        = string
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform state (created by bootstrap)"
  type        = string
}

variable "sql_s3_prefix" {
  description = "S3 key prefix for uploaded SQL files"
  type        = string
  default     = "sql/"
}

variable "python_s3_prefix" {
  description = "S3 key prefix for uploaded Python files"
  type        = string
  default     = "lib/python/"
}

variable "deployment_alias" {
  description = "Step Functions deployment alias name. If null, no alias is created"
  type        = string
  default     = null
}

variable "owner_team_email" {
  description = "Email of the owner team"
  type        = string
}

variable "tech_team_email" {
  description = "Email of the technical team"
  type        = string
}

variable "github_repo_id" {
  description = "GitHub repository ID for tagging purposes"
  type        = string
  default     = "GITHUB_REPOSITORY_TAG_PLACEHOLDER"
}

variable "github_repo_name" {
  description = "GitHub repository name for tagging purposes"
  type        = string
  default     = "GITHUB_REPOSITORY_TAG_PLACEHOLDER"
}

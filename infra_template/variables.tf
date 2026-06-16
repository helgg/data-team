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

# ---------------------------------------------------------------------------
# ASL global template variables — injected into every templatefile() call
# ---------------------------------------------------------------------------

variable "bucket" {
  description = "S3 bucket name used as the primary data lake bucket in ASL templates"
  type        = string
  default     = ""
}

variable "glue_db" {
  description = "AWS Glue database name referenced in ASL templates"
  type        = string
  default     = ""
}

variable "pipeline_1_table" {
  description = "Glue table name for pipeline 1, referenced in ASL templates"
  type        = string
  default     = ""
}

variable "pipeline_2_table" {
  description = "Glue table name for pipeline 2, referenced in ASL templates"
  type        = string
  default     = ""
}

variable "glue_main_job_name" {
  description = "Name of the main Glue ETL job referenced in ASL templates"
  type        = string
  default     = ""
}

variable "glue_heimdall_job_name" {
  description = "Name of the Heimdall Glue job referenced in ASL templates"
  type        = string
  default     = ""
}

variable "glue_hermes_job_name" {
  description = "Name of the Hermes Glue job referenced in ASL templates"
  type        = string
  default     = ""
}

variable "glue_repair_job_name" {
  description = "Name of the repair Glue job referenced in ASL templates"
  type        = string
  default     = ""
}

variable "region_name" {
  description = "AWS region name passed as a parameter in ASL templates"
  type        = string
  default     = ""
}

variable "partition_name" {
  description = "Partition column name used in ASL templates"
  type        = string
  default     = ""
}

variable "partition_type" {
  description = "Partition type (e.g. date, string) used in ASL templates"
  type        = string
  default     = ""
}

variable "owner_email" {
  description = "Email address of the pipeline owner, used for notifications in ASL templates"
  type        = string
  default     = ""
}

variable "members" {
  description = "Comma-separated list of team member emails for notifications in ASL templates"
  type        = string
  default     = ""
}

variable "group_name" {
  description = "Group or squad name used in ASL templates"
  type        = string
  default     = ""
}

variable "reprocessamento" {
  description = "Flag indicating whether reprocessing is enabled in ASL templates"
  type        = string
  default     = "true"
}

variable "range_reprocessamento" {
  description = "Number of days for reprocessing window in ASL templates"
  type        = string
  default     = "7"
}

variable "defasagem" {
  description = "Lag in days applied during processing in ASL templates"
  type        = string
  default     = "1"
}

variable "ignore_partitions_tb_name" {
  description = "Table name used to look up partitions to ignore in ASL templates"
  type        = string
  default     = ""
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

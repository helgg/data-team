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
  description = "ARN of the pre-existing IAM execution role for Step Functions"
  type        = string
  sensitive   = true
}

variable "glue_database_name" {
  description = "Glue Data Catalog database name to monitor for partition creation"
  type        = string
}

variable "glue_table_name" {
  description = "Glue Data Catalog table name to monitor for partition creation"
  type        = string
}

variable "assets_bucket_name" {
  description = "Base name for the S3 assets bucket (SQL and Python files)"
  type        = string
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform state (created by bootstrap)"
  type        = string
}

variable "step_function_name" {
  description = "Name identifier for the Step Functions state machine"
  type        = string
  default     = "orchestrator"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "schedule_expression" {
  description = "EventBridge cron expression for the fallback scheduled trigger"
  type        = string
  default     = "cron(0 6 * * ? *)"
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

variable "kms_key_arn" {
  description = "ARN of the KMS CMK for encrypting CloudWatch Logs and S3. If empty, SSE-S3 is used"
  type        = string
  default     = ""
}

variable "include_execution_data" {
  description = "Whether to log Step Functions execution input/output. Disable in prod to prevent PII leakage"
  type        = bool
  default     = false
}

variable "log_level" {
  description = "Step Functions logging level (OFF, ERROR, FATAL, ALL). Use ERROR in prod"
  type        = string
  default     = "ERROR"
}

variable "enable_alarms" {
  description = "Whether to create CloudWatch alarms for the state machine"
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications. If empty, alarms have no actions"
  type        = string
  default     = ""
}

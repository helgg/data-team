variable "name" {
  description = "Name identifier for the state machine and related resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

variable "step_function_role_arn" {
  description = "ARN of the pre-existing IAM execution role for Step Functions"
  type        = string
}

variable "glue_database_name" {
  description = "Glue Data Catalog database name to monitor for partition creation"
  type        = string
}

variable "glue_table_name" {
  description = "Glue Data Catalog table name to monitor for partition creation"
  type        = string
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

variable "kms_key_arn" {
  description = "ARN of the KMS CMK for encrypting CloudWatch Logs. If empty, SSE default is used"
  type        = string
  default     = ""
}

variable "include_execution_data" {
  description = "Whether to log execution input/output in CloudWatch. Disable in prod to prevent PII leakage"
  type        = bool
  default     = false
}

variable "log_level" {
  description = "Step Functions logging level (OFF, ERROR, FATAL, ALL). Use ERROR or FATAL in prod"
  type        = string
  default     = "ERROR"

  validation {
    condition     = contains(["OFF", "ERROR", "FATAL", "ALL"], var.log_level)
    error_message = "log_level must be one of: OFF, ERROR, FATAL, ALL."
  }
}

variable "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications. If empty, alarms are created without actions"
  type        = string
  default     = ""
}

variable "enable_alarms" {
  description = "Whether to create CloudWatch alarms for the state machine"
  type        = bool
  default     = true
}

variable "asl_file_path" {
  description = "Absolute path to the ASL JSON file for this state machine"
  type        = string
}

variable "asl_template_vars" {
  description = "Variables injected into the ASL templatefile (e.g. glue_database_name, glue_table_name, s3_input_path, s3_output_path). Use $${...} in ASL to escape Step Functions JSONPath dollar signs."
  type        = any
  default     = {}
}

variable "common_tags" {
  description = "Map of mandatory tags applied to all resources"
  type        = map(string)
}

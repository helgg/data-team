variable "bucket_name" {
  description = "Name of the S3 bucket for SQL and Python assets"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

variable "sql_assets_path" {
  description = "Local filesystem path containing SQL files to upload"
  type        = string
}

variable "python_assets_path" {
  description = "Local filesystem path containing Python files to upload"
  type        = string
}

variable "sql_s3_prefix" {
  description = "S3 key prefix for SQL files"
  type        = string
  default     = "sql/"
}

variable "python_s3_prefix" {
  description = "S3 key prefix for Python files"
  type        = string
  default     = "lib/python/"
}

variable "versioning_enabled" {
  description = "Enable S3 versioning on the assets bucket"
  type        = bool
  default     = true
}

variable "lifecycle_transition_days" {
  description = "Days after which objects transition to STANDARD_IA storage class"
  type        = number
  default     = 90
}

variable "common_tags" {
  description = "Map of mandatory tags applied to all resources"
  type        = map(string)
}

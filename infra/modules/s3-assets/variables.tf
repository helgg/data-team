variable "bucket_name" {
  description = "Name of the existing S3 bucket to upload assets to"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be 'dev' or 'prod'."
  }
}

variable "sql_assets_path" {
  description = "Local filesystem path containing SQL files to upload"
  type        = string
}

variable "python_assets_path" {
  description = "Local filesystem path containing Python files to upload"
  type        = string
}

variable "s3_common_prefix" {
  description = "Root S3 key prefix shared by all uploaded assets (must end with /)"
  type        = string
  default     = "assets/"
}

variable "sql_s3_prefix" {
  description = "S3 sub-prefix for SQL files, appended after s3_common_prefix"
  type        = string
  default     = "sql/"
}

variable "python_s3_prefix" {
  description = "S3 sub-prefix for Python files, appended after s3_common_prefix"
  type        = string
  default     = "python/"
}

variable "kms_key_arn" {
  description = "ARN of the KMS CMK for object encryption. Empty string uses SSE-S3 (AES256)."
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Map of tags to apply to all S3 objects"
  type        = map(string)
  default     = {}
}

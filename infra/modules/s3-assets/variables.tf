variable "bucket_name" {
  description = "bucket S3 destino dos assets"
  type        = string
}

variable "environment" {
  description = "ambiente (dev ou prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be 'dev' or 'prod'."
  }
}

variable "sql_assets_path" {
  description = "caminho local dos arquivos SQL"
  type        = string
}

variable "python_assets_path" {
  description = "caminho local dos arquivos Python"
  type        = string
}

variable "s3_common_prefix" {
  description = "prefixo S3 comum (deve terminar com /)"
  type        = string
  default     = "assets/"
}

variable "sql_s3_prefix" {
  description = "sub-prefixo S3 para SQL"
  type        = string
  default     = "sql/"
}

variable "python_s3_prefix" {
  description = "sub-prefixo S3 para Python"
  type        = string
  default     = "python/"
}

variable "kms_key_arn" {
  description = "ARN da KMS CMK (vazio = SSE-S3/AES256)"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "tags dos objetos S3"
  type        = map(string)
  default     = {}
}

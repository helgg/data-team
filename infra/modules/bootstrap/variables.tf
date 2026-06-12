variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

variable "common_tags" {
  description = "Map of mandatory tags applied to all resources"
  type        = map(string)
}

output "state_machine_arns" {
  description = "ARNs of all Step Functions state machines, keyed by state machine name"
  value       = { for k, v in module.state_machine : k => v.state_machine_arn }
}

output "state_machine_names" {
  description = "Full resource names of all state machines, keyed by state machine name"
  value       = { for k, v in module.state_machine : k => v.state_machine_name }
}

output "assets_bucket_name" {
  description = "Name of the S3 bucket containing SQL and Python assets"
  value       = module.s3_assets.bucket_name
}

output "assets_bucket_arn" {
  description = "ARN of the S3 assets bucket"
  value       = module.s3_assets.bucket_arn
}

output "sql_objects_keys" {
  description = "S3 keys of all uploaded SQL files"
  value       = module.s3_assets.sql_objects_keys
}

output "python_objects_keys" {
  description = "S3 keys of all uploaded Python files"
  value       = module.s3_assets.python_objects_keys
}

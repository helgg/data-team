output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = module.step_function.state_machine_arn
}

output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = module.step_function.state_machine_name
}

output "log_group_name" {
  description = "CloudWatch log group for state machine executions"
  value       = module.step_function.log_group_name
}

output "eventbridge_rule_glue_arn" {
  description = "ARN of the EventBridge rule triggered by Glue partition creation"
  value       = module.step_function.eventbridge_rule_glue_arn
}

output "eventbridge_rule_schedule_arn" {
  description = "ARN of the EventBridge fallback scheduled rule"
  value       = module.step_function.eventbridge_rule_schedule_arn
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

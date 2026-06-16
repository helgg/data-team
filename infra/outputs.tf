output "state_machine_arns" {
  description = "ARNs of all Step Functions state machines, keyed by state machine name"
  value       = { for k, v in module.state_machine : k => v.state_machine_arn }
}

output "state_machine_names" {
  description = "Full resource names of all state machines, keyed by state machine name"
  value       = { for k, v in module.state_machine : k => v.state_machine_name }
}

output "sql_objects_keys" {
  description = "S3 keys of all uploaded SQL files"
  value       = module.s3_assets.uploaded_sql_keys
  sensitive   = true
}

output "python_objects_keys" {
  description = "S3 keys of all uploaded Python files"
  value       = module.s3_assets.uploaded_python_keys
  sensitive   = true
}

output "eventbridge_rule_arns" {
  description = "ARNs of all EventBridge rules that trigger Step Functions, keyed by trigger name"
  value       = { for k, r in aws_cloudwatch_event_rule.this : k => r.arn }
}

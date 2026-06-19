output "state_machine_arns" {
  description = "ARNs das state machines"
  value       = { for k, v in module.state_machine : k => v.state_machine_arn }
}

output "state_machine_names" {
  description = "nomes das state machines"
  value       = { for k, v in module.state_machine : k => v.state_machine_name }
}

output "sql_objects_keys" {
  description = "chaves S3 dos arquivos SQL"
  value       = module.s3_assets.uploaded_sql_keys
  sensitive   = true
}

output "python_objects_keys" {
  description = "chaves S3 dos arquivos Python"
  value       = module.s3_assets.uploaded_python_keys
  sensitive   = true
}

output "eventbridge_rule_arns" {
  description = "ARNs das regras EventBridge"
  value       = { for k, r in aws_cloudwatch_event_rule.this : k => r.arn }
}

output "glue_job_names" {
  description = "nomes finais (AWS) dos jobs Glue, chaveados pela chave lógica do map var.glue_jobs"
  value       = { for k, v in module.glue_jobs : k => v.glue_job_name }
}

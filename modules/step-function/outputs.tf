output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.this.arn
}

output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.this.name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group for state machine executions"
  value       = aws_cloudwatch_log_group.this.name
}

output "eventbridge_rule_glue_arn" {
  description = "ARN of the EventBridge rule that triggers on Glue partition creation"
  value       = aws_cloudwatch_event_rule.glue_partition.arn
}

output "eventbridge_rule_schedule_arn" {
  description = "ARN of the EventBridge scheduled fallback rule"
  value       = aws_cloudwatch_event_rule.daily_fallback.arn
}

output "eventbridge_invoke_role_arn" {
  description = "ARN of the IAM role used by EventBridge to invoke Step Functions"
  value       = aws_iam_role.eb_invoke_sf.arn
}

output "alarm_executions_failed_arn" {
  description = "ARN of the CloudWatch alarm for failed executions"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.executions_failed[0].arn : null
}

output "alarm_executions_timed_out_arn" {
  description = "ARN of the CloudWatch alarm for timed out executions"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.executions_timed_out[0].arn : null
}

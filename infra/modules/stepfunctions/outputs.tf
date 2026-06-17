output "state_machine_arn" {
  description = "ARN da state machine"
  value       = aws_sfn_state_machine.this.arn
}

output "state_machine_name" {
  description = "nome da state machine"
  value       = aws_sfn_state_machine.this.name
}

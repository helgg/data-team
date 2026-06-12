output "state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket"
  value       = aws_s3_bucket.state.arn
}

output "state_bucket_name" {
  description = "Name of the Terraform state S3 bucket"
  value       = aws_s3_bucket.state.id
}

output "state_bucket_id" {
  description = "ID of the Terraform state S3 bucket"
  value       = aws_s3_bucket.state.id
}

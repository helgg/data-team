output "bucket_arn" {
  description = "ARN of the assets S3 bucket"
  value       = aws_s3_bucket.assets.arn
}

output "bucket_name" {
  description = "Name of the assets S3 bucket"
  value       = aws_s3_bucket.assets.id
}

output "bucket_id" {
  description = "ID of the assets S3 bucket"
  value       = aws_s3_bucket.assets.id
}

output "sql_objects_keys" {
  description = "S3 keys of all uploaded SQL files"
  value       = [for obj in aws_s3_object.sql : obj.key]
}

output "python_objects_keys" {
  description = "S3 keys of all uploaded Python files"
  value       = [for obj in aws_s3_object.python : obj.key]
}

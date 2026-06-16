output "uploaded_sql_keys" {
  description = "List of S3 object keys uploaded from the SQL assets path"
  value       = [for obj in aws_s3_object.sql : obj.key]
  sensitive   = true
}

output "uploaded_python_keys" {
  description = "List of S3 object keys uploaded from the Python assets path"
  value       = [for obj in aws_s3_object.python : obj.key]
  sensitive   = true
}

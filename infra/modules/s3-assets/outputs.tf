output "uploaded_sql_keys" {
  description = "chaves S3 dos arquivos SQL enviados"
  value       = [for obj in aws_s3_object.sql : obj.key]
  sensitive   = true
}

output "uploaded_python_keys" {
  description = "chaves S3 dos arquivos Python enviados"
  value       = [for obj in aws_s3_object.python : obj.key]
  sensitive   = true
}

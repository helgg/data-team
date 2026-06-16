resource "aws_s3_object" "sql" {
  for_each = fileset(var.sql_assets_path, "**/*.sql")

  bucket                 = var.bucket_name
  key                    = "${var.s3_common_prefix}${var.sql_s3_prefix}${each.value}"
  source                 = "${var.sql_assets_path}/${each.value}"
  etag                   = filemd5("${var.sql_assets_path}/${each.value}")
  content_type           = "application/sql"
  server_side_encryption = var.kms_key_arn != "" ? "aws:kms" : "AES256"
  kms_key_id             = var.kms_key_arn != "" ? var.kms_key_arn : null
  tags                   = var.common_tags
}

resource "aws_s3_object" "python" {
  for_each = fileset(var.python_assets_path, "**/*.py")

  bucket                 = var.bucket_name
  key                    = "${var.s3_common_prefix}${var.python_s3_prefix}${each.value}"
  source                 = "${var.python_assets_path}/${each.value}"
  etag                   = filemd5("${var.python_assets_path}/${each.value}")
  content_type           = "text/x-python"
  server_side_encryption = var.kms_key_arn != "" ? "aws:kms" : "AES256"
  kms_key_id             = var.kms_key_arn != "" ? var.kms_key_arn : null
  tags                   = var.common_tags
}

locals {
  sql_files    = fileset(var.sql_assets_path, "**/*.sql")
  python_files = fileset(var.python_assets_path, "**/*.py")
}

resource "aws_s3_bucket" "assets" {
  bucket = var.bucket_name

  tags = merge(var.common_tags, {
    Name = var.bucket_name
  })
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = var.lifecycle_transition_days
      storage_class = "STANDARD_IA"
    }
  }

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  depends_on = [aws_s3_bucket_versioning.assets]
}

resource "aws_s3_object" "sql" {
  for_each = local.sql_files

  bucket       = aws_s3_bucket.assets.id
  key          = "${var.sql_s3_prefix}${each.value}"
  source       = "${var.sql_assets_path}/${each.value}"
  etag         = filemd5("${var.sql_assets_path}/${each.value}")
  content_type = "text/plain"

  tags = merge(var.common_tags, {
    Name = each.value
  })
}

resource "aws_s3_object" "python" {
  for_each = local.python_files

  bucket       = aws_s3_bucket.assets.id
  key          = "${var.python_s3_prefix}${each.value}"
  source       = "${var.python_assets_path}/${each.value}"
  etag         = filemd5("${var.python_assets_path}/${each.value}")
  content_type = "text/x-python"

  tags = merge(var.common_tags, {
    Name = each.value
  })
}

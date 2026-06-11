aws_region   = "us-east-1"
environment  = "prod"
project      = "data-platform"
owner        = "data-team"
cost_center  = "eng-001"

# IAM - pre-existing execution role ARN
step_function_role_arn = "arn:aws:iam::ACCOUNT_ID:role/YOUR_SF_EXECUTION_ROLE"

# Glue source table to monitor
glue_database_name = "your_glue_database"
glue_table_name    = "your_source_table"

# S3 buckets (account_id suffix added automatically)
state_bucket_name  = "data-platform-prod-tfstate"
assets_bucket_name = "data-platform-prod-assets"

# Step Function
step_function_name     = "orchestrator"
log_retention_days     = 90
schedule_expression    = "cron(0 4 * * ? *)"
log_level              = "ERROR"
include_execution_data = false

# KMS — set to CMK ARN for prod (recommended)
kms_key_arn = ""

# Alarms
enable_alarms       = true
alarm_sns_topic_arn = ""

# S3 prefixes for assets
sql_s3_prefix    = "sql/"
python_s3_prefix = "lib/python/"

aws_region  = "us-east-1"
environment = "dev"
project     = "data-platform"
owner       = "data-team"
cost_center = "eng-001"

# IAM - pre-existing execution role ARN (shared across all state machines)
step_function_role_arn = "arn:aws:iam::123456789012:role/mock-sf-execution-role"

# S3 buckets (account_id suffix added automatically by locals)
state_bucket_name  = "data-platform-dev-tfstate"
assets_bucket_name = "data-platform-dev-assets"

# State machines — key must match asl/<key>.json filename
state_machines = {
  "orchestrator" = {
    # EventBridge trigger — monitors the primary SOT table
    glue_database_name  = "workspace_db"
    glue_table_name     = "sepj_sot_ga4_perfis_operadores"
    s3_input_path       = ""
    s3_output_path      = ""
    schedule_expression = "cron(0 6 * * ? *)"

    # ASL template variables
    bucket                    = "itau-self-xxxxxxx"
    glue_db                   = "workspace_db"
    pipeline_1_table          = "sepj_sot_ga4_perfis_operadores"
    pipeline_2_table          = "sepj_spec_ga4_perfis_operadores_analitica"
    glue_main_job_name        = "Yggdra"
    glue_heimdall_job_name    = "YGGDRA - Heimdall"
    glue_hermes_job_name      = "Yggdra_Hermes"
    glue_repair_job_name      = "repair_table_perfis_operadores_iam"
    region_name               = "sa-east-1"
    partition_name            = "anomesdia"
    partition_type            = "anomesdia"
    owner_email               = "xxxxxxx"
    members                   = "xxxxxxx"
    group_name                = "Yggdra_Hermes_DD"
    reprocessamento           = "true"
    range_reprocessamento     = "7"
    defasagem                 = "1"
    ignore_partitions_tb_name = "tb_depara_funis"
  }
  # Add more state machines here — each key creates a new State Machine + EventBridge rules
  # "pipeline-customers" = {
  #   glue_database_name  = "db_raw"
  #   glue_table_name     = "customers"
  #   s3_input_path       = "s3://data-platform-dev-assets-ACCOUNT_ID/raw/customers"
  #   s3_output_path      = "s3://data-platform-dev-assets-ACCOUNT_ID/trusted/customers"
  # }
}

# Global config (applies to all state machines)
log_retention_days     = 30
log_level              = "ALL"
include_execution_data = true
kms_key_arn            = ""
enable_alarms          = true
alarm_sns_topic_arn    = ""

# S3 prefixes for assets
sql_s3_prefix    = "sql/"
python_s3_prefix = "lib/python/"

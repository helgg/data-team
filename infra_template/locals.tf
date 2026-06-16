locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }

  assets_bucket_name = "${var.assets_bucket_name}-${data.aws_caller_identity.current.account_id}"

  # Auto-discovery: any *.json dropped in stepfunctions/ becomes a state machine
  stepfunction_files = fileset("${path.module}/stepfunctions", "*.json")
  stepfunctions      = { for f in local.stepfunction_files : trimsuffix(f, ".json") => f }

  # Auto-discovery: any *.json dropped in trigger/ becomes an EventBridge rule
  trigger_files = fileset("${path.module}/trigger", "*.json")
  triggers      = { for f in local.trigger_files : trimsuffix(f, ".json") => jsondecode(file("${path.module}/trigger/${f}")) }

  # Global ASL template variables — injected into every templatefile() call
  asl_vars = {
    bucket                    = var.bucket
    glue_db                   = var.glue_db
    pipeline_1_table          = var.pipeline_1_table
    pipeline_2_table          = var.pipeline_2_table
    glue_main_job_name        = var.glue_main_job_name
    glue_heimdall_job_name    = var.glue_heimdall_job_name
    glue_hermes_job_name      = var.glue_hermes_job_name
    glue_repair_job_name      = var.glue_repair_job_name
    region_name               = var.region_name
    partition_name            = var.partition_name
    partition_type            = var.partition_type
    owner_email               = var.owner_email
    members                   = var.members
    group_name                = var.group_name
    reprocessamento           = var.reprocessamento
    range_reprocessamento     = var.range_reprocessamento
    defasagem                 = var.defasagem
    ignore_partitions_tb_name = var.ignore_partitions_tb_name
  }
}

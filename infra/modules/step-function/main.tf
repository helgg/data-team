data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/states/${var.name}-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null

  tags = merge(var.common_tags, {
    Name = "/aws/states/${var.name}-${var.environment}"
  })
}

resource "aws_sfn_state_machine" "this" {
  name     = "${var.name}-${var.environment}"
  role_arn = var.step_function_role_arn
  type     = "STANDARD"

  definition = templatefile(var.asl_file_path, {})

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.this.arn}:*"
    include_execution_data = var.include_execution_data
    level                  = var.log_level
  }

  tags = merge(var.common_tags, {
    Name = "${var.name}-${var.environment}"
  })
}

resource "aws_cloudwatch_event_rule" "glue_partition" {
  name        = "${var.name}-${var.environment}-glue-partition-created"
  description = "Triggers Step Function when a new partition is created in the source Glue table"

  event_pattern = jsonencode({
    source      = ["aws.glue"]
    detail-type = ["Glue Data Catalog Table State Change"]
    account     = [data.aws_caller_identity.current.account_id]
    detail = {
      databaseName = [var.glue_database_name]
      tableName    = [var.glue_table_name]
      typeOfChange = ["CreatePartition", "BatchCreatePartition"]
    }
  })

  tags = merge(var.common_tags, {
    Name = "${var.name}-${var.environment}-glue-partition-created"
  })
}

resource "aws_cloudwatch_event_target" "glue_partition_to_sf" {
  rule      = aws_cloudwatch_event_rule.glue_partition.name
  target_id = "StepFunctions"
  arn       = aws_sfn_state_machine.this.arn
  role_arn  = aws_iam_role.eb_invoke_sf.arn
}

resource "aws_cloudwatch_event_rule" "daily_fallback" {
  name                = "${var.name}-${var.environment}-daily-fallback"
  description         = "Fallback scheduled trigger in case the Glue partition event is missed"
  schedule_expression = var.schedule_expression

  tags = merge(var.common_tags, {
    Name = "${var.name}-${var.environment}-daily-fallback"
  })
}

resource "aws_cloudwatch_event_target" "daily_fallback_to_sf" {
  rule      = aws_cloudwatch_event_rule.daily_fallback.name
  target_id = "StepFunctions"
  arn       = aws_sfn_state_machine.this.arn
  role_arn  = aws_iam_role.eb_invoke_sf.arn
}

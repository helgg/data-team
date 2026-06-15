################################
# STATE MACHINE RESOURCE
################################
resource "terraform_data" "kms_arn_trigger" {
  input = var.create_kms ? one(aws_kms_key.this).arn : var.kms_arn
}

resource "aws_sfn_state_machine" "this" {
  name                = var.state_machine_name
  role_arn            = var.state_machine_iam_role_arn
  type                = var.state_machine_type
  definition          = var.state_machine_definition
  tags                = local.resource_tags
  publish             = var.deployment_alias != null ? true : false

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.log_group_for_state_machine.arn}:*"
    include_execution_data = true
    level                  = var.state_machine_log_level
  }
  tracing_configuration {
    enabled = var.xray_active_tracing
  }
  encryption_configuration {
    kms_key_id          = var.create_kms ? one(aws_kms_key.this).arn : one(data.aws_kms_key.this).arn
    type                = "CUSTOMER_MANAGED_KMS_KEY"
  }

  lifecycle {
    ignore_changes = [
      encryption_configuration
    ]

    replace_triggered_by = [
      terraform_data.kms_arn_trigger
    ]
  }
}

data "aws_sfn_state_machine_versions" "versions" {
  statemachine_arn = aws_sfn_state_machine.this.arn
}

resource "aws_sfn_alias" "alias" {
  name = var.deployment_alias

  routing_configuration {
    state_machine_version_arn = aws_sfn_state_machine.this.state_machine_version_arn
    weight                    = 100
  }
}


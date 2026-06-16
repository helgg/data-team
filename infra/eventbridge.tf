# ---------------------------------------------------------------------------
# IAM Role — EventBridge → Step Functions
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "eventbridge_sf_trust" {
  statement {
    sid     = "AllowEventBridgeAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "eventbridge_sf" {
  name               = "${local.name_prefix}-eventbridge-sf"
  description        = "Permite ao EventBridge iniciar execuções do Step Functions"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_sf_trust.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "eventbridge_sf_permissions" {
  statement {
    sid       = "AllowStartExecutionOnManagedSMs"
    effect    = "Allow"
    actions   = ["states:StartExecution"]
    resources = [for k, m in module.state_machine : m.state_machine_arn]
  }
}

resource "aws_iam_role_policy" "eventbridge_sf" {
  name   = "${local.name_prefix}-eventbridge-sf-policy"
  role   = aws_iam_role.eventbridge_sf.id
  policy = data.aws_iam_policy_document.eventbridge_sf_permissions.json
}

# ---------------------------------------------------------------------------
# Regras EventBridge — uma por JSON em trigger/
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "this" {
  for_each = local.triggers

  name                = "${local.name_prefix}-${each.key}"
  description         = "Trigger agendado para a state machine ${each.key}"
  schedule_expression = each.value.schedule_expression
  event_bus_name      = "default"
  tags                = local.common_tags
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = local.triggers

  rule      = aws_cloudwatch_event_rule.this[each.key].name
  target_id = "StepFunctions"
  arn       = module.state_machine[each.key].state_machine_arn
  role_arn  = aws_iam_role.eventbridge_sf.arn
}

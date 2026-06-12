locals {
  alarm_actions          = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  state_machine_name     = aws_sfn_state_machine.this.name
  glue_rule_name         = aws_cloudwatch_event_rule.glue_partition.name
}

resource "aws_cloudwatch_metric_alarm" "executions_failed" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.state_machine_name}-executions-failed"
  alarm_description   = "CRITICAL: Step Function execution failed. Check execution history for error details. Runbook: https://wiki.internal/runbooks/step-functions-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.this.arn
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.common_tags, {
    Name     = "${local.state_machine_name}-executions-failed"
    Severity = "critical"
  })
}

resource "aws_cloudwatch_metric_alarm" "executions_timed_out" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.state_machine_name}-executions-timed-out"
  alarm_description   = "CRITICAL: Step Function execution timed out. The state machine exceeded its maximum execution duration. Runbook: https://wiki.internal/runbooks/step-functions-timeout"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsTimedOut"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.this.arn
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.common_tags, {
    Name     = "${local.state_machine_name}-executions-timed-out"
    Severity = "critical"
  })
}

resource "aws_cloudwatch_metric_alarm" "execution_throttled" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.state_machine_name}-execution-throttled"
  alarm_description   = "WARNING: Step Function executions are being throttled. AWS service quota may need to be increased. Runbook: https://wiki.internal/runbooks/step-functions-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionThrottled"
  namespace           = "AWS/States"
  period              = 600
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.this.arn
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.common_tags, {
    Name     = "${local.state_machine_name}-execution-throttled"
    Severity = "warning"
  })
}

resource "aws_cloudwatch_metric_alarm" "executions_not_started" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.state_machine_name}-executions-not-started"
  alarm_description   = "WARNING: No Step Function executions started in the last 25 hours. The pipeline may not have been triggered by EventBridge (Glue event missed and fallback cron did not fire). Runbook: https://wiki.internal/runbooks/step-functions-no-trigger"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 25
  datapoints_to_alarm = 25
  metric_name         = "ExecutionsStarted"
  namespace           = "AWS/States"
  period              = 3600
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "breaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.this.arn
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.common_tags, {
    Name     = "${local.state_machine_name}-executions-not-started"
    Severity = "warning"
  })
}

resource "aws_cloudwatch_metric_alarm" "eventbridge_glue_failed_invocations" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.glue_rule_name}-failed-invocations"
  alarm_description   = "CRITICAL: EventBridge rule for Glue partition creation failed to invoke Step Functions. The target invocation was rejected or the rule has a misconfiguration. Runbook: https://wiki.internal/runbooks/eventbridge-failed-invocation"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedInvocations"
  namespace           = "AWS/Events"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    RuleName = local.glue_rule_name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.common_tags, {
    Name     = "${local.glue_rule_name}-failed-invocations"
    Severity = "critical"
  })
}

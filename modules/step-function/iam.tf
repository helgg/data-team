data "aws_iam_policy_document" "eb_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eb_invoke_sf" {
  name               = "${var.name}-${var.environment}-eb-invoke-sf"
  assume_role_policy = data.aws_iam_policy_document.eb_assume_role.json

  tags = merge(var.common_tags, {
    Name = "${var.name}-${var.environment}-eb-invoke-sf"
  })
}

data "aws_iam_policy_document" "eb_invoke_sf" {
  statement {
    actions   = ["states:StartExecution"]
    resources = [aws_sfn_state_machine.this.arn]
  }
}

resource "aws_iam_role_policy" "eb_invoke_sf" {
  name   = "invoke-step-function"
  role   = aws_iam_role.eb_invoke_sf.id
  policy = data.aws_iam_policy_document.eb_invoke_sf.json
}

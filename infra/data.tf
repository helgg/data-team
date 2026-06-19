data "aws_caller_identity" "current" {}

# Key policy da KMS key compartilhada dos jobs Glue (CloudWatch Logs, job
# bookmarks e S3 encryption). Segregação administração/uso por exigência de
# revisão de segurança (guardrails-engineer):
#   - KeyAdministration: ações de gestão da chave (não inclui Decrypt/Encrypt
#     de dados), restritas a var.kms_key_admin_role_arns (default: conta root,
#     já que nenhum role de administração de KMS dedicado existe ainda neste
#     projeto — ajustar var.kms_key_admin_role_arns quando houver).
#   - KeyUsageByGlueExecRole: a role de execução do Glue pode usar a chave
#     para criptografar/decriptar os dados que ela já tem acesso.
#   - KeyUsageByServices: Glue e CloudWatch Logs podem usar a chave em nome
#     do job, restrito à conta (Glue) e ao log group deste pipeline
#     (CloudWatch, via aws:SourceArn) para evitar uso por outros projetos
#     que porventura compartilhem a conta.
data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid    = "KeyAdministration"
    effect = "Allow"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]

    principals {
      type = "AWS"
      identifiers = length(var.kms_key_admin_role_arns) > 0 ? var.kms_key_admin_role_arns : [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    resources = ["*"]
  }

  statement {
    sid    = "KeyUsageByGlueExecRole"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/iamsr/role-glue-exec"]
    }

    resources = ["*"]
  }

  statement {
    sid    = "KeyUsageByGlueService"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "KeyUsageByCloudWatchLogs"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }

    resources = ["*"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*"]
    }
  }
}

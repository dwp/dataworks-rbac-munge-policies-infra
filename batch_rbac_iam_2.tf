
# AWS Batch Job IAM resources
data "aws_iam_policy_document" "batch_assume_policy" {
  statement {
    sid    = "BatchAssumeRolePolicy"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "batch_rbac_role" {
  name               = "batch_rbac_role"
  assume_role_policy = data.aws_iam_policy_document.batch_assume_policy.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "batch_rbac_iam_policy" {
  role   = aws_iam_role.batch_rbac_role.id
  policy = data.aws_iam_policy_document.batch_rbac_iam_document.json
}

data "aws_iam_policy_document" "batch_rbac_iam_document" {
  statement {
    sid = "PolicyMungeBatchRbacIam"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:DetachRolePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:CreateRole",
      "iam:ListRoles",
      "iam:DeleteRole",
      "iam:GetRolePolicy",
      "iam:ListPolicies",
      "iam:ListPolicyVersions",
      "iam:ListRoleTags",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateRole"
    ]
    resources = [
      "arn:aws:iam::${local.account[local.environment]}:policy/emrfs/*",
      "arn:aws:iam::${local.account[local.environment]}:role/emrfs/*"
    ]
  }

  statement {
    sid = "ReadPoliciesAndRoles"
    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListPolicies"
    ]
    resources = [
      "arn:aws:iam::${local.account[local.environment]}:policy/*",
      "arn:aws:iam::${local.account[local.environment]}:role/*"
    ]
  }

  statement {
    sid    = "AllowGetCredentials"
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      data.terraform_remote_state.aws-analytical-environment-app.outputs.rbac_db.secrets.client_credentials["batch-rbac"].arn,
    ]
  }

  statement {
    sid       = "AllowRdsDataExecute"
    effect    = "Allow"
    actions   = ["rds-data:ExecuteStatement"]
    resources = [data.terraform_remote_state.aws-analytical-environment-app.outputs.rbac_db.rds_cluster.arn]
  }

  statement {
    sid       = "AllowKmsDescribeKey"
    effect    = "Allow"
    actions   = ["kms:DescribeKey"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      values   = ["alias/*-home"]
      variable = "kms:RequestAlias"
    }
  }
}

resource "aws_iam_role_policy" "batch_rbac_cognito_policy" {
  role   = aws_iam_role.batch_rbac_role.name
  policy = data.aws_iam_policy_document.batch_rbac_cognito_document.json
}

data "aws_iam_policy_document" "batch_rbac_cognito_document" {
  statement {
    sid = "BatchRbacCognito"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "mgmt_rbac_lambda_role" {
  count              = length(regexall("management", local.environment)) > 0 ? 1 : 0
  name               = "${local.name_prefix}-mgmt-cognito-rbac-role-${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.rbac_lambdas_trust_policy.json
  tags               = local.common_tags
  provider           = aws.management
}

data "aws_iam_policy_document" "rbac_lambdas_trust_policy" {

  statement {
    sid     = "MgmtBatchAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.batch_rbac_role.arn]
    }
  }
}
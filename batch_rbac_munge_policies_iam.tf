# AWS Batch sec resources
data "aws_iam_role" "aws_batch_service_role" {
  name = "aws_batch_service_role"
}

# EC2 IAM resources
resource "aws_iam_role" "ec2_role_munge_policies_batch" {
  name = "ec2_role_munge_policies_batch"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        }
      }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_instance_profile_munge_policies_batch" {
  name = "ec2_instance_profile_munge_policies_batch"
  role = aws_iam_role.ec2_role_munge_policies_batch.name
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_batch_rbac_ecr" {
  role       = aws_iam_role.ec2_role_munge_policies_batch.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_batch_rbac" {
  role       = aws_iam_role.ec2_role_munge_policies_batch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
resource "aws_iam_role_policy_attachment" "ec2_for_ssm_attachment" {
  role       = aws_iam_role.ec2_role_munge_policies_batch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# AWS Batch Job IAM resources
data "aws_iam_policy_document" "batch_assume_policy" {
  statement {
    sid    = "BatchAssumeRolePolicy"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com", "ecs.amazonaws.com"]
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
  name   = "batch-rbac-iam"
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
}


resource "aws_iam_role_policy" "batch_rbac_secrets_policy" {
  name   = "batch-rbac-secrets"
  role   = aws_iam_role.batch_rbac_role.id
  policy = data.aws_iam_policy_document.batch_rbac_secrets_document.json
}

data "aws_iam_policy_document" "batch_rbac_secrets_document" {
  statement {
    sid    = "AllowGetCredentials"
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      data.terraform_remote_state.aws-analytical-environment-app.outputs.rbac_db.secrets.client_credentials["emrfs-lambda"].arn,
    ]
  }
}

resource "aws_iam_role_policy" "batch_rbac_rds_policy" {
  name   = "batch-rbac-rds"
  role   = aws_iam_role.batch_rbac_role.id
  policy = data.aws_iam_policy_document.batch_rbac_rds_document.json
}
data "aws_iam_policy_document" "batch_rbac_rds_document" {
  statement {
    sid       = "AllowRdsDataExecute"
    effect    = "Allow"
    actions   = ["rds-data:ExecuteStatement"]
    resources = [data.terraform_remote_state.aws-analytical-environment-app.outputs.rbac_db.rds_cluster.arn]
  }
}

resource "aws_iam_role_policy" "batch_rbac_kms_policy" {
  name   = "batch-rbac-kms"
  role   = aws_iam_role.batch_rbac_role.id
  policy = data.aws_iam_policy_document.batch_rbac_kms_document.json
}
data "aws_iam_policy_document" "batch_rbac_kms_document" {
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
  name   = "batch-rbac-cognito"
  role   = aws_iam_role.batch_rbac_role.name
  policy = data.aws_iam_policy_document.batch_rbac_cognito_document.json
}
data "aws_iam_policy_document" "batch_rbac_cognito_document" {
  statement {
    sid       = "CognitoRdsSyncMgmt"
    actions   = ["sts:AssumeRole"]
    resources = [data.terraform_remote_state.aws-analytical-environment-app.outputs.emrfs_lambdas.policy_munge_lambda.environment[0].variables.MGMT_ACCOUNT_ROLE_ARN]
  }
}
resource "aws_iam_role_policy" "batch_rbac_cloudwatch_policy" {
  name   = "batch-rbac-cloudwatch"
  role   = aws_iam_role.batch_rbac_role.name
  policy = data.aws_iam_policy_document.batch_rbac_cloudwatch_document.json
}


data "aws_iam_policy_document" "batch_rbac_cloudwatch_document" {
  statement {
    sid = "BatchRbacCloudWatchBasic"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

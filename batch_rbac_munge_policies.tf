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
# # AWS Batch Job IAM resources
# data "aws_iam_policy_document" "batch_assume_policy" {
#   statement {
#     sid    = "BatchAssumeRolePolicy"
#     effect = "Allow"
#     actions = [
#       "sts:AssumeRole",
#     ]
#     principals {
#       identifiers = ["ecs-tasks.amazonaws.com"]
#       type        = "Service"
#     }
#   }
# }

# resource "aws_iam_role" "batch_job_role_munge_policies" {
#   name               = "batch_job_role_munge_policies"
#   assume_role_policy = data.aws_iam_policy_document.batch_assume_policy.json
#   tags               = local.common_tags
# }

# data "aws_iam_policy_document" "emrfs_iam_assume_role" {
#   statement {
#     sid     = "AllowAssumeRole"
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]
#     principals {
#       type = "AWS"
#       identifiers = [
#         "arn:aws:iam::${local.account[local.environment]}:role/AE_EMR_EC2_Role"
#       ]
#     }
#   }
# }
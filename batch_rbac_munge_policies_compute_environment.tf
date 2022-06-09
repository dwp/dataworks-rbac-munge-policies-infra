# AWS Batch compute resources
resource "aws_batch_compute_environment" "batch_rbac_munge_policies_compute" {
  compute_environment_name_prefix = "batch_rbac_munge_policies_compute"
  service_role                    = data.aws_iam_role.aws_batch_service_role.arn
  type                            = "MANAGED"

  compute_resources {
    image_id            = var.ecs_hardened_ami_id
    instance_role       = aws_iam_instance_profile.ec2_instance_profile_munge_policies_batch.arn
    instance_type       = ["optimal"]
    allocation_strategy = "BEST_FIT_PROGRESSIVE"

    min_vcpus     = 0
    desired_vcpus = local.batch_rbac_munge_policies_compute_environment_desired_cpus[local.environment]
    max_vcpus     = local.batch_rbac_munge_policies_compute_environment_max_cpus[local.environment]

    security_group_ids = [local.batch_rbac_compute_security_group_id]
    subnets            = local.batch_rbac_compute_subnets
    type               = "EC2"

    tags = merge(
      local.common_tags,
      {
        Name         = "batch-munge-policies",
        Persistence  = "Ignore",
        AutoShutdown = "False",
      }
    )
  }

  lifecycle {
    ignore_changes        = [compute_resources.0.desired_vcpus]
    create_before_destroy = true
  }
}

resource "aws_batch_job_definition" "rbac_munge_policy" {
  name = "rbac_munge_policy_job"
  type = "container"

  container_properties = <<CONTAINER_PROPERTIES
  {
      "image": "${local.rbac_munge_policies_image}",
      "jobRoleArn" : "${aws_iam_role.batch_job_role_munge_policies.arn}",
      "memory": ${local.batch_rbac_munge_policies_container_memory[local.environment]},
      "vcpus": ${local.batch_rbac_munge_policies_container_vcpu[local.environment]},
      "environment": [
          {"name": "DATABASE_CLUSTER_ARN", "value": "${data.terraform_remote_state.aws-analytical-environment-app.outputs.rbac_db.rds_cluster.arn}"},
          {"name": "DATABASE_NAME", "value": "${data.terraform_remote_state.aws-analytical-environment-app.outputs.rbac_db.db_name}"},
          {"name": "DATABASE_SECRET_ARN", "value": "${data.terraform_remote_state.aws-analytical-environment-app.outputs.rbac_db.secrets.client_credentials["batch-rbac"].arn}"},
          {"name": "COMMON_TAGS", "value": "${join(",", [for key, val in local.common_tags : "${key}:${val}"])}"},
          {"name": "ASSUME_ROLE_POLICY_JSON", "value": "${local.emrfs_iam_assume_role}"},
          {"name": "S3FS_BUCKET_ARN", "value": "${data.terraform_remote_state.aws-analytical-environment-app.outputs.s3fs_bucket.arn}"},
          {"name": "S3FS_KMS_ARN", "value": "${data.terraform_remote_state.aws-analytical-environment-app.outputs.s3fs_bucket_kms_arn}"},
          {"name": "REGION", "value": "eu-west-2"},
          {"name": "COGNITO_USERPOOL_ID", "value": "${data.terraform_remote_state.cognito.outputs.cognito.user_pool_id}"},
          {"name": "LOG_LEVEL", "value": "INFO"},
          {"name": "ENVIRONMENT", "value": "${local.environment}"},
          {"name": "APPLICATION", "value": "${local.rbac_munge_policies_application_name}"}
      ],
      "ulimits": [
        {
          "hardLimit": 1024,
          "name": "nofile",
          "softLimit": 1024
        }
      ]
  }
  CONTAINER_PROPERTIES
}

resource "aws_batch_job_queue" "rbac_munge_policies_queue" {
  compute_environments = [aws_batch_compute_environment.batch_rbac_munge_policies_compute.arn]
  name                 = "rbac_munge_policies_queue"
  priority             = 10
  state                = "ENABLED"
  tags                 = merge({ "Name" : "rbac_munge_policies_queue" }, local.common_tags)
}

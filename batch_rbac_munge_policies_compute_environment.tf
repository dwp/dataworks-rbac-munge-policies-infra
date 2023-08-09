# AWS Batch compute resources
resource "aws_batch_compute_environment" "batch_rbac_munge_policies_compute" {
  compute_environment_name_prefix = "batch_rbac_munge_policies_compute"
  service_role                    = data.aws_iam_role.aws_batch_service_role.arn
  type                            = "MANAGED"

  compute_resources {
    instance_role       = aws_iam_instance_profile.ec2_instance_profile_munge_policies_batch.arn
    instance_type       = ["optimal"]
    allocation_strategy = "BEST_FIT_PROGRESSIVE"

    min_vcpus     = 0
    desired_vcpus = local.batch_rbac_munge_policies_compute_environment_desired_cpus[local.environment]
    max_vcpus     = local.batch_rbac_munge_policies_compute_environment_max_cpus[local.environment]

    security_group_ids = [local.batch_rbac_compute_security_group_id]
    subnets            = local.batch_rbac_compute_subnets
    type               = "EC2"

    launch_template {
      launch_template_id      = aws_launch_template.batch_rbac_munge_policies.id
      version                 = aws_launch_template.batch_rbac_munge_policies.latest_version
    }

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

resource "aws_launch_template" "batch_rbac_munge_policies" {
  name     = "batch-munge-policies"
  image_id = var.ecs_hardened_ami_id

  user_data = base64encode(templatefile("files/batch/userdata.tpl", {
    region                                           = data.aws_region.current.name
    name                                             = "batch-munge-policies"
    proxy_port                                       = var.proxy_port
    proxy_host                                       = data.terraform_remote_state.aws_analytical_environment_infra.outputs.internet_proxy_dns_name
    hcs_environment                                  = local.hcs_environment[local.environment]
    s3_scripts_bucket                                = data.terraform_remote_state.common.outputs.config_bucket.id
    s3_script_logrotate                              = aws_s3_object.batch_logrotate_script.id
    s3_script_cloudwatch_shell                       = aws_s3_object.batch_cloudwatch_script.id
    s3_script_logging_shell                          = aws_s3_object.batch_logging_script.id
    s3_script_config_hcs_shell                       = aws_s3_object.batch_config_hcs.id
    cwa_namespace                                    = local.cw_rbac_munge_agent_namespace
    cwa_log_group_name                               = "${local.cw_rbac_munge_agent_namespace}-${local.environment}"
    cwa_metrics_collection_interval                  = local.cw_agent_metrics_collection_interval
    cwa_cpu_metrics_collection_interval              = local.cw_agent_cpu_metrics_collection_interval
    cwa_disk_measurement_metrics_collection_interval = local.cw_agent_disk_measurement_metrics_collection_interval
    cwa_disk_io_metrics_collection_interval          = local.cw_agent_disk_io_metrics_collection_interval
    cwa_mem_metrics_collection_interval              = local.cw_agent_mem_metrics_collection_interval
    cwa_netstat_metrics_collection_interval          = local.cw_agent_netstat_metrics_collection_interval
    install_tenable                                  = local.tenable_install[local.environment]
    install_trend                                    = local.trend_install[local.environment]
    install_tanium                                   = local.tanium_install[local.environment]
    tanium_server_1                                  = data.terraform_remote_state.aws_analytical_environment_infra.outputs.tanium_service_endpoint.dns
    tanium_server_2                                  = local.tanium2
    tanium_env                                       = local.tanium_env[local.environment]
    tanium_port                                      = var.tanium_port_1
    tanium_log_level                                 = local.tanium_log_level[local.environment]
    tenant                                           = local.tenant
    tenantid                                         = local.tenantid
    token                                            = local.token
    policyid                                         = local.policy_id[local.environment]

  }))

  instance_initiated_shutdown_behavior = "terminate"

  tags = merge(
    local.common_tags,
    {
      Name = "batch-munge-policies"
    }
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name                = "batch-munge-policies",
        AutoShutdown        = local.rbac_munge_asg_autoshutdown[local.environment],
        SSMEnabled          = local.rbac_munge_asg_ssmenabled[local.environment],
        Persistence         = "Ignore",
        propagate_at_launch = true,
      }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      local.common_tags,
      {
        Name = "batch-munge-policies",
      }
    )
  }
}

resource "aws_batch_job_definition" "rbac_munge_policy" {
  name = "rbac_munge_policy_job"
  type = "container"

  container_properties = <<CONTAINER_PROPERTIES
  {
      "image": "${local.rbac_munge_policies_image}",
      "jobRoleArn" : "${aws_iam_role.batch_rbac_role.arn}",
      "memory": ${local.batch_rbac_munge_policies_container_memory[local.environment]},
      "vcpus": ${local.batch_rbac_munge_policies_container_vcpu[local.environment]},
      "environment": [
          {"name": "DATABASE_CLUSTER_ARN", "value": "${data.terraform_remote_state.aws-analytical-environment-app.outputs.rbac_db.rds_cluster.arn}"},
          {"name": "DATABASE_NAME", "value": "${data.terraform_remote_state.aws-analytical-environment-app.outputs.rbac_db.db_name}"},
          {"name": "DATABASE_SECRET_ARN", "value": "${data.terraform_remote_state.aws-analytical-environment-app.outputs.rbac_db.secrets.client_credentials["emrfs-lambda"].arn}"},
          {"name": "COMMON_TAGS", "value": "${join(",", [for key, val in local.common_tags : "${key}:${val}"])}"},
          {"name": "ASSUME_ROLE_POLICY_JSON", "value": ${jsonencode(data.terraform_remote_state.aws-analytical-environment-app.outputs.emrfs_iam_assume_role_json)}},
          {"name": "S3FS_BUCKET_ARN", "value": "${data.terraform_remote_state.aws-analytical-environment-app.outputs.s3fs_bucket.arn}"},
          {"name": "S3FS_KMS_ARN", "value": "${data.terraform_remote_state.aws-analytical-environment-app.outputs.s3fs_bucket_kms_arn}"},
          {"name": "REGION", "value": "eu-west-2"},
          {"name": "MGMT_ACCOUNT_ROLE_ARN", "value": "${data.terraform_remote_state.aws-analytical-environment-app.outputs.emrfs_lambdas.policy_munge_lambda.environment[0].variables.MGMT_ACCOUNT_ROLE_ARN}"},
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

resource "aws_cloudwatch_log_group" "rbac_munge_policies_cw_Log_group" {
  name              = local.cw_rbac_munge_agent_log_group_name
  retention_in_days = 180
  tags              = local.common_tags
}

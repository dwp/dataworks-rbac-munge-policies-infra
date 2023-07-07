locals {
  batch_rbac_vpc_id                    = data.terraform_remote_state.aws_analytical_environment_infra.outputs.vpc.aws_vpc.id
  batch_rbac_compute_subnets           = data.terraform_remote_state.aws_analytical_environment_infra.outputs.vpc.aws_subnets_private[*].id
  batch_rbac_compute_security_group_id = aws_security_group.batch_rbac_vpce_analytical_env_security_group.id

  route_table_ids = data.terraform_remote_state.aws_analytical_environment_infra.outputs.vpc.aws_route_table_private_ids
  nat_gateway_ids = data.terraform_remote_state.aws_analytical_environment_infra.outputs.vpc.aws_nat_gateways.*.id

  internal_compute_vpc_prefix_list_ids_s3 = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.prefix_list_ids.s3

  rbac_munge_policies_image            = "${local.account.management}.${data.terraform_remote_state.aws_ingestion.outputs.vpc.vpc.ecr_dkr_domain_name}/dataworks-rbac-munge-policies:${var.image_version.rbac-munge-policies[local.environment]}"
  rbac_munge_policies_application_name = "rbac-munge-policies"

  cognito_user_pool_id = data.terraform_remote_state.cognito.outputs.cognito.user_pool_id

  management_role_arn = "arn:aws:iam::${local.account[local.management_account[local.environment]]}:role/${var.assume_role}"
  mgmt_account        = local.account[local.environment]
  name_prefix         = "batch-rbac"

  batch_rbac_munge_policies_container_vcpu = {
    development = 2
    qa          = 2
    integration = 2
    preprod     = 8
    production  = 16
  }

  batch_rbac_munge_policies_container_memory = {
    development = 2048
    qa          = 2048
    integration = 2048
    preprod     = 4096
    production  = 8192
  }

  batch_rbac_munge_policies_compute_environment_desired_cpus = {
    development = 10
    qa          = 10
    integration = 10
    preprod     = 10
    production  = 24
  }

  batch_rbac_munge_policies_compute_environment_max_cpus = {
    development = 16
    qa          = 16
    integration = 16
    preprod     = 24
    production  = 32
  }

  common_config_bucket         = data.terraform_remote_state.common.outputs.config_bucket
  common_config_bucket_cmk_arn = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn

  cw_rbac_munge_agent_namespace                 = "/app/rbac-munge"
  cw_rbac_munge_agent_log_group_name            = "/app/rbac-munge"
  

  cw_rbac_munge_main_agent_namespace                    = "/app/rbac-munge"
  cw_agent_metrics_collection_interval                  = 60
  cw_agent_cpu_metrics_collection_interval              = 60
  cw_agent_disk_measurement_metrics_collection_interval = 60
  cw_agent_disk_io_metrics_collection_interval          = 60
  cw_agent_mem_metrics_collection_interval              = 60
  cw_agent_netstat_metrics_collection_interval          = 60


  rbac_munge_asg_autoshutdown = {
    development = "False"
    qa          = "False"
    integration = "False"
    preprod     = "False"
    production  = "False"
  }

  rbac_munge_asg_ssmenabled = {
    development = "True"
    qa          = "True"
    integration = "True"
    preprod     = "False"
    production  = "False"
  }

  tenable_install = {
    development    = "true"
    qa             = "true"
    integration    = "true"
    preprod        = "true"
    production     = "true"
    management-dev = "true"
    management     = "true"
  }

  trend_install = {
    development    = "true"
    qa             = "true"
    integration    = "true"
    preprod        = "true"
    production     = "true"
    management-dev = "true"
    management     = "true"
  }

  tanium_install = {
    development    = "false"
    qa             = "false"
    integration    = "false"
    preprod        = "false"
    production     = "false"
    management-dev = "false"
    management     = "false"
  }


  ## Tanium config
  ## Tanium Servers
  tanium1 = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).tanium[local.environment].server_1
  tanium2 = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).tanium[local.environment].server_2

  ## Tanium Env Config
  tanium_env = {
    development    = "pre-prod"
    qa             = "prod"
    integration    = "prod"
    preprod        = "prod"
    production     = "prod"
    management-dev = "pre-prod"
    management     = "prod"
  }

  ## Tanium prefix list for TGW for Security Group rules
  tanium_prefix = {
    development    = [data.aws_ec2_managed_prefix_list.list.id]
    qa             = [data.aws_ec2_managed_prefix_list.list.id]
    integration    = [data.aws_ec2_managed_prefix_list.list.id]
    preprod        = [data.aws_ec2_managed_prefix_list.list.id]
    production     = [data.aws_ec2_managed_prefix_list.list.id]
    management-dev = [data.aws_ec2_managed_prefix_list.list.id]
    management     = [data.aws_ec2_managed_prefix_list.list.id]
  }

  tanium_log_level = {
    development    = "41"
    qa             = "41"
    integration    = "41"
    preprod        = "41"
    production     = "41"
    management-dev = "41"
    management     = "41"
  }

  ## Trend config
  tenant   = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).trend.tenant
  tenantid = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).trend.tenantid
  token    = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).trend.token

  policy_id = {
    development    = "69"
    qa             = "69"
    integration    = "69"
    preprod        = "69"
    production     = "69"
    management-dev = "69"
    management     = "69"
  }

}

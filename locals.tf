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

}

locals {
  # internal_compute_vpc_prefix_list_ids_s3 = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.prefix_list_ids.s3
  batch_rbac_compute_vpc               = data.terraform_remote_state.aws_analytical_environment_infra.outputs.vpc.aws_vpc.id
  batch_rbac_compute_subnets           = data.terraform_remote_state.internal_compute.outputs.compute_environment_subnet.ids
  batch_rbac_compute_security_group_id = data.terraform_remote_state.internal_compute.outputs.vpce_security_groups.s3_object_tagger_batch_vpce_security_group.id

  rbac_munge_policies_image            = "${local.account.management-dev}.${data.terraform_remote_state.aws_ingestion.outputs.vpc.vpc.ecr_dkr_domain_name}/dataworks-rbac-munge-policies:${var.image_version.rbac-munge-policies[local.environment]}"
  rbac_munge_policies_application_name = "rbac-munge-policies"

  cognito_user_pool_id = data.terraform_remote_state.cognito.outputs.cognito.user_pool_id

  management_role_arn = "arn:aws:iam::${local.account[local.management_account[local.environment]]}:role/${var.assume_role}"
  mgmt_account        = local.account[local.environment]
  name_prefix         = "rbac-batch"

  emrfs_iam_assume_role = "{'Version':'2012-10-17','Statement':[{'Sid':'AllowAssumeRole','Effect':'Allow','Action':'sts:AssumeRole','Principal':{'AWS':'arn:aws:iam::${local.account[local.environment]}:role/AE_EMR_EC2_Role'}}]}"
  # emrfs_iam_assume_role = jsonencode(data.aws_iam_policy_document.emrfs_iam_assume_role.json)

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

output "batch_rbac_compute_vpc" {
  value = local.batch_rbac_compute_vpc
}
output "batch_rbac_compute_subnets" {
  value = local.batch_rbac_compute_subnets
}
output "batch_rbac_compute_security_group_id" {
  value = local.batch_rbac_compute_security_group_id
}

output "internal_compute_batch_rbac_compute_vpc" {
  value = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.vpc.id
}
output "internal_compute_batch_rbac_compute_subnets" {
  value = data.terraform_remote_state.internal_compute.outputs.compute_environment_subnet.ids
}
output "internal_compute_batch_rbac_compute_security_group_id" {
  value = data.terraform_remote_state.internal_compute.outputs.vpce_security_groups.s3_object_tagger_batch_vpce_security_group.id
}
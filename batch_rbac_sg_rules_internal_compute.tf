
resource "aws_security_group" "batch_rbac_vpce_internal_compute_security_group" {
  name                   = "batch_rbac_vpce_internal_compute_security_group"
  description            = "RBAC batch security group to access the internal compute VPC endpoints"
  revoke_rules_on_delete = true
  vpc_id                 = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.vpc.id
  tags                   = merge(local.common_tags, { Name = "batch_rbac_vpce_internal_compute_security_group" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "internal_compute_vpc_endpoints_ingress_from_batch_rbac" {
  description              = "Accept VPCE traffic"
  type                     = "ingress"
  source_security_group_id = aws_security_group.batch_rbac_vpce_internal_compute_security_group.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  security_group_id        = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.interface_vpce_sg_id
}

resource "aws_security_group_rule" "internet_proxy_vpce_ingress_from_batch_rbac" {
  description              = "Allow proxy access from batch rbac"
  type                     = "ingress"
  source_security_group_id = aws_security_group.batch_rbac_vpce_internal_compute_security_group.id
  protocol                 = "tcp"
  from_port                = 3128
  to_port                  = 3128
  security_group_id        = data.terraform_remote_state.internal_compute.outputs.internet_proxy.sg
}

resource "aws_security_group_rule" "batch_rbac_egress_to_internal_compute_vpc_endpoint" {
  description              = "Allow batch rbac to reach out to internal compute VPC Endpoints"
  type                     = "egress"
  source_security_group_id = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.interface_vpce_sg_id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  security_group_id        = aws_security_group.batch_rbac_vpce_internal_compute_security_group.id
}

resource "aws_security_group_rule" "batch_rbac_egress_to_internet_proxy" {
  description              = "Batch rbac to Internet Proxy"
  type                     = "egress"
  source_security_group_id = data.terraform_remote_state.internal_compute.outputs.internet_proxy.sg
  protocol                 = "tcp"
  from_port                = 3128
  to_port                  = 3128
  security_group_id        = aws_security_group.batch_rbac_vpce_internal_compute_security_group.id
}

resource "aws_security_group_rule" "batch_rbac_egress_to_s3" {
  description       = "Batch rbac to S3"
  type              = "egress"
  prefix_list_ids   = [local.internal_compute_vpc_prefix_list_ids_s3]
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.batch_rbac_vpce_internal_compute_security_group.id
}

resource "aws_security_group_rule" "batch_rbac_egress_to_s3_http" {
  description       = "Batch rbac to S3 http for YUM"
  type              = "egress"
  prefix_list_ids   = [local.internal_compute_vpc_prefix_list_ids_s3]
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  security_group_id = aws_security_group.batch_rbac_vpce_internal_compute_security_group.id
}
resource "aws_route" "analytical_env_to_nat_gw" {
  count                  = length(local.route_table_ids) == length(local.nat_gateway_ids) ? length(local.route_table_ids) : 0
  route_table_id         = element(local.route_table_ids, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(local.nat_gateway_ids, count.index)
}

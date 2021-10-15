#
# AWS VPC setup
#
data "aws_availability_zones" "available" {}
resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc["cidr"]}"
  enable_dns_hostnames = "${var.vpc["dns_hostnames"]}"
  enable_dns_support   = "${var.vpc["dns_support"]}"
  instance_tenancy     = "${var.vpc["tenancy"]}"

  tags = tomap({
    "Name"="${var.environment}_${var.cluster_name}_vpc",
    "kubernetes.io/cluster/${var.environment}_${var.cluster_name}"="shared"
  })
}

#
# AWS Subnets setup
#
locals{
  private_subnets_count = "${length(var.vpc.private_subnets) + length(var.vpc.elasticache_subnets) + length(var.vpc.rds_subnets)}"
}
resource "aws_subnet" "public_subnets" {
  count                   = "${length(var.vpc.public_subnets)}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index % length(data.aws_availability_zones.available.names))}"
  cidr_block              = "${var.vpc.public_subnets[count.index]}"
  map_public_ip_on_launch = true
  tags = tomap({
     "Name"="${var.environment}_${var.cluster_name}_public_${count.index}",
     "kubernetes.io/cluster/${var.environment}_${var.cluster_name}"="shared"
    })
}

resource "aws_subnet" "private_subnets" {
  count                   = "${length(var.vpc.private_subnets)}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index % length(data.aws_availability_zones.available.names))}"
  cidr_block              = "${var.vpc.private_subnets[count.index]}"
  map_public_ip_on_launch = false
  tags = tomap({
     "Name"="${var.environment}_${var.cluster_name}_private_${count.index}",
     "kubernetes.io/cluster/${var.environment}_${var.cluster_name}"="shared"
    })
}

#
# RDS subnet
#
resource "aws_subnet" "private_rds_subnets" {
  count                   = "${length(var.vpc.rds_subnets)}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index % length(data.aws_availability_zones.available.names))}"
  cidr_block              = "${var.vpc.rds_subnets[count.index]}"
  map_public_ip_on_launch = false
  tags = tomap({
     "Name"="${var.environment}_${var.cluster_name}_private_rds_${count.index}",
    })
}

resource "aws_db_subnet_group" "rds" {
  count      = "${length(var.vpc.rds_subnets) > 0 ? 1 : 0}"
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids =  ["${aws_subnet.private_rds_subnets.*.id}"]
}

#
# ElastiCache subnet
#
resource "aws_subnet" "private_elasticache_subnets" {
  count = "${length(var.vpc.elasticache_subnets)}"

  vpc_id                  = "${aws_vpc.vpc.id}"
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index % length(data.aws_availability_zones.available.names))}"
  cidr_block              = "${var.vpc.elasticache_subnets[count.index]}"
  map_public_ip_on_launch = false
  tags = tomap({
     "Name"="${var.environment}_private_es_${count.index}",
    })
}

resource "aws_elasticache_subnet_group" "elasticache" {
  count       = "${length(var.vpc.elasticache_subnets) > 0 ? 1 : 0}"
  name        = "${var.environment}-es-subnet-group"
  description = "ElastiCache subnet group"
  subnet_ids  = ["${aws_subnet.private_elasticache_subnets.*.id}"]
}

#
# AWS IGW setup
#
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "${var.environment}_${var.cluster_name}_igw"
  }
}

#
# AWS Nat Gateway setup
# Used for the private subnets
resource "aws_eip" "nat_gw" {
  count       = "${local.private_subnets_count> 0 ? 1 :0}"
  vpc         = true
  depends_on  = [aws_subnet.private_subnets]
}

resource "aws_nat_gateway" "nat_gw" {
  count         = "${local.private_subnets_count > 0 ? 1 : 0}"
  allocation_id = "${aws_eip.nat_gw.0.id}"
  subnet_id     = "${aws_subnet.public_subnets.0.id}"
  tags = {
    Name = "${var.environment}_${var.cluster_name}_nat"
  }
  depends_on = [aws_subnet.private_subnets,aws_subnet.public_subnets]
}


#
# AWS Route Table setup
# Grant the VPC internet access on its main route table

resource "aws_route_table" "public_route_table" {
  count = "${length(var.vpc.public_subnets) > 0 ? 1 : 0}"
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "${var.environment}_${var.cluster_name}_public_route"
  }
}
resource "aws_route" "internet_gateway_to_public_route_table" {
  count = "${length(var.vpc.public_subnets) > 0 ? 1 : 0}"
  route_table_id         = "${aws_route_table.public_route_table.0.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}


resource "aws_route_table" "private_route_table" {
  count             = "${length(var.vpc.private_subnets) > 0 ? 1 : 0}"
  vpc_id            = "${aws_vpc.vpc.id}"
  tags = {
    Name = "${var.environment}_${var.cluster_name}_private_route"
  }
}

resource "aws_route" "nat_gateway_to_private_route_table" {
  count                  = "${length(var.vpc.private_subnets) > 0 ? 1 : 0}"
  route_table_id         = "${aws_route_table.private_route_table.0.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat_gw.0.id}"
}


resource "aws_route_table" "rds_route_table" {
  count = "${length(var.vpc.rds_subnets) > 0 ? 1 : 0}"
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "${var.environment}_${var.cluster_name}_rds_route"
  }
}

resource "aws_route" "nat_gateway_to_rds_route_table" {
  count = "${length(var.vpc.rds_subnets) > 0 ? 1 : 0}"
  route_table_id         = "${aws_route_table.rds_route_table.0.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat_gw.0.id}"
}


resource "aws_route_table" "elasticache_route_table" {
  count = "${length(var.vpc.elasticache_subnets) > 0 ? 1 : 0}"
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "${var.environment}_${var.cluster_name}_rds_route"
  }
}

resource "aws_route" "nat_gateway_to_elasticache_route_table" {
  count = "${length(var.vpc.elasticache_subnets) > 0 ? 1 : 0}"
  route_table_id         = "${aws_route_table.elasticache_route_table.0.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat_gw.0.id}"
}


resource "aws_route_table_association" "public_subnet" {
  count          = "${length(var.vpc.public_subnets)}"
  subnet_id      = "${element(aws_subnet.public_subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_route_table.0.id}"
}


resource "aws_route_table_association" "private_subnet" {
  count          = "${length(var.vpc.private_subnets)}"
  subnet_id      = "${element(aws_subnet.private_subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.private_route_table.0.id}"
}

resource "aws_route_table_association" "rds_subnet" {
  count          = "${length(var.vpc.rds_subnets)}"
  subnet_id      = "${element(aws_subnet.private_rds_subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.rds_route_table.0.id}"
}

resource "aws_route_table_association" "elasticache_subnet" {
  count          = "${length(var.vpc.elasticache_subnets)}"
  subnet_id      = "${element(aws_subnet.private_elasticache_subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.elasticache_route_table.0.id}"
}

#
# VPC Peering connection in same region
#

resource "aws_vpc_peering_connection" "peering" {
  count         = "${length(keys(var.vpc_to_connect)) > 0 ? 1 : 0}"
  peer_vpc_id   = "${var.vpc_to_connect["vpc_id"]}"
  vpc_id        = "${aws_vpc.vpc.id}"
  auto_accept   = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name = "${var.environment}_${var.cluster_name}_peering_${var.vpc_to_connect["vpc_id"]}"
  }
}

resource "aws_route" "route_from_private_to_peering" {
  count                     = "${length(keys(var.vpc_to_connect)) > 0? 1:0}"
  route_table_id            = "${aws_route_table.private_route_table.0.id}"
  destination_cidr_block    = "${var.vpc_to_connect["vpc_cidr"]}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peering.0.id}"
  depends_on                = [aws_vpc.vpc,aws_vpc_peering_connection.peering]
}


resource "aws_route" "route_from_public_to_peering" {
  count                     = "${length(keys(var.vpc_to_connect)) > 0 ? 1:0}"
  route_table_id            = "${aws_route_table.public_route_table.0.id}"
  destination_cidr_block    = "${var.vpc_to_connect["vpc_cidr"]}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peering.0.id}"
  depends_on                = [aws_vpc.vpc,aws_vpc_peering_connection.peering]
}
resource "aws_route" "route_from_elasticache_to_peering" {
  count                     = "${length(keys(var.vpc_to_connect)) > 0 && length(var.vpc.elasticache_subnets) > 0 ? 1 : 0  }"
  route_table_id            = "${aws_route_table.elasticache_route_table.0.id}"
  destination_cidr_block    = "${var.vpc_to_connect["vpc_cidr"]}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peering.0.id}"
  depends_on                = [aws_vpc.vpc,aws_vpc_peering_connection.peering]
}


resource "aws_route" "route_from_rds_to_peering" {
  count                     = "${length(keys(var.vpc_to_connect)) > 0  && length(var.vpc.rds_subnets) >0 ? 1 : 0 }"
  route_table_id            = "${aws_route_table.rds_route_table.0.id}"
  destination_cidr_block    = "${var.vpc_to_connect["vpc_cidr"]}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peering.0.id}"
  depends_on                = [aws_vpc.vpc,aws_vpc_peering_connection.peering]
}

# Routes from accepter vpc to this requester vpc

resource "aws_route" "route_from_accepter_private_to_peering" {
  count                     = "${length(keys(var.vpc_to_connect)) > 0? 1 : 0 }"
  route_table_id            = "${var.vpc_to_connect["private_route_table"]}"
  destination_cidr_block    = "${var.vpc["cidr"]}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peering.0.id}"
  depends_on                = [aws_vpc.vpc,aws_vpc_peering_connection.peering]
}

resource "aws_route" "route_from_accepter_public_to_peering" {
  count                     = "${length(keys(var.vpc_to_connect)) > 0 ? 1 : 0 }"
  route_table_id            = "${var.vpc_to_connect["public_route_table"]}"
  destination_cidr_block    = "${var.vpc["cidr"]}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peering.0.id}"
  depends_on                = [aws_vpc.vpc,aws_vpc_peering_connection.peering]
}

// resource "aws_flow_log" "vpc" {
//  iam_role_arn    = "arn"
//  log_destination = "log"
// traffic_type    = "ALL"
//   vpc_id          = "${aws_vpc.vpc.id}"
// }

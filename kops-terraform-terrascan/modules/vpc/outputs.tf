output "vpc" {
  value = "${aws_vpc.vpc}"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "vpc_cidr" {
  value = "${aws_vpc.vpc.cidr_block}"
}

output "public_subnets" {
  value = aws_subnet.public_subnets.*
}

output "private_subnets" {
  value = aws_subnet.private_subnets.*
}

output "private_route_table" {
  value = "${aws_route_table.private_route_table.0.id}"
}

output "public_route_table" {
  value = "${aws_route_table.public_route_table.0.id}"
}

resource "aws_vpc" "default" {
  cidr_block = "${var.vpc-block}"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  tags = {
    Name = "k8s"
  }
}
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
  tags = {
    Name = "k8s"
  }
}
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}
resource "aws_subnet" "ks" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${var.subnet-block}"
  map_public_ip_on_launch = true
  tags = {
    Name = "k8s"
  }
}

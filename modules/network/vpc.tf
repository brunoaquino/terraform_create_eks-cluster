resource "aws_vpc" "eks_vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = format("%s-vpc", var.cluster_name)
  }
}

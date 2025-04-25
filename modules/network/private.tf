resource "aws_subnet" "eks_subnet_private_1a" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = var.private_subnets[0]
  availability_zone = var.availability_zones[0]

  tags = {
    Name                                        = "${var.cluster_name}-private-${var.availability_zones[0]}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "eks_subnet_private_1b" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = var.private_subnets[1]
  availability_zone = var.availability_zones[1]

  tags = {
    Name                                        = "${var.cluster_name}-private-${var.availability_zones[1]}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "eks_private_rt_association_1a" {
  subnet_id      = aws_subnet.eks_subnet_private_1a.id
  route_table_id = aws_route_table.eks_nat_rt.id
}

resource "aws_route_table_association" "eks_private_rt_association_1b" {
  subnet_id      = aws_subnet.eks_subnet_private_1b.id
  route_table_id = aws_route_table.eks_nat_rt.id
}

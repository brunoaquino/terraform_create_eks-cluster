# Subnets dedicadas para banco de dados
resource "aws_subnet" "eks_subnet_database_1a" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.database_subnets[0]
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.cluster_name}-database-${var.availability_zones[0]}"
  }
}

resource "aws_subnet" "eks_subnet_database_1b" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.database_subnets[1]
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.cluster_name}-database-${var.availability_zones[1]}"
  }
}

# Route table separada para subnets de banco de dados
resource "aws_route_table" "eks_database_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  # Não adicionamos rota para internet aqui,
  # fazendo com que as subnets fiquem isoladas

  tags = {
    Name = format("%s-database-rt", var.cluster_name)
  }
}

# Associações de route table para subnets de banco de dados
resource "aws_route_table_association" "eks_database_rt_association_1a" {
  subnet_id      = aws_subnet.eks_subnet_database_1a.id
  route_table_id = aws_route_table.eks_database_rt.id
}

resource "aws_route_table_association" "eks_database_rt_association_1b" {
  subnet_id      = aws_subnet.eks_subnet_database_1b.id
  route_table_id = aws_route_table.eks_database_rt.id
}

# Network ACL específica para subnets de banco de dados
resource "aws_network_acl" "database" {
  vpc_id = aws_vpc.eks_vpc.id

  subnet_ids = [
    aws_subnet.eks_subnet_database_1a.id,
    aws_subnet.eks_subnet_database_1b.id
  ]

  # Permitir tráfego de subnets privadas para porta PostgreSQL
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.private_subnets[0]
    from_port  = 5432
    to_port    = 5432
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = var.private_subnets[1]
    from_port  = 5432
    to_port    = 5432
  }

  # Permitir tráfego de subnets privadas para porta MySQL/Aurora
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = var.private_subnets[0]
    from_port  = 3306
    to_port    = 3306
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = var.private_subnets[1]
    from_port  = 3306
    to_port    = 3306
  }

  # Respostas para conexões de banco de dados
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.private_subnets[0]
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = var.private_subnets[1]
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = format("%s-database-nacl", var.cluster_name)
  }
}

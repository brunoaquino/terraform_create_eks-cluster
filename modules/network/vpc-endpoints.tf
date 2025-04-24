# Security Group para endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = format("%s-vpc-endpoints-sg", var.cluster_name)
  description = "Security group para VPC endpoints"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Permitir HTTPS da VPC"
  }

  tags = {
    Name = format("%s-vpc-endpoints-sg", var.cluster_name)
  }
}

# Endpoint para ECR API
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.eks_vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.eks_subnet_private_1a.id, aws_subnet.eks_subnet_private_1b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = format("%s-ecr-api-endpoint", var.cluster_name)
  }
}

# Endpoint para ECR DKR (Docker Registry)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.eks_vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.eks_subnet_private_1a.id, aws_subnet.eks_subnet_private_1b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = format("%s-ecr-dkr-endpoint", var.cluster_name)
  }
}

# Endpoint para S3 (Gateway type)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.eks_vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.eks_nat_rt.id]

  tags = {
    Name = format("%s-s3-endpoint", var.cluster_name)
  }
}

# Endpoint para CloudWatch Logs
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.eks_vpc.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.eks_subnet_private_1a.id, aws_subnet.eks_subnet_private_1b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = format("%s-logs-endpoint", var.cluster_name)
  }
}

# Endpoint para STS (necessário para IAM roles)
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.eks_vpc.id
  service_name        = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.eks_subnet_private_1a.id, aws_subnet.eks_subnet_private_1b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = format("%s-sts-endpoint", var.cluster_name)
  }
}

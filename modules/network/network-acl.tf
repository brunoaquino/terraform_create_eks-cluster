# Network ACL para subnets privadas
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.eks_vpc.id

  subnet_ids = [
    aws_subnet.eks_subnet_private_1a.id,
    aws_subnet.eks_subnet_private_1b.id
  ]

  # Permitir todo tráfego de saída
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  egress {
    protocol   = "udp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  # Permitir tráfego de entrada das subnets públicas
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/16" # VPC CIDR
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "udp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.0.0/16" # VPC CIDR
    from_port  = 0
    to_port    = 65535
  }

  # Permitir tráfego de retorno (para respostas de conexões iniciadas)
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = format("%s-private-nacl", var.cluster_name)
  }
}

# Network ACL para subnets públicas
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.eks_vpc.id

  subnet_ids = [
    aws_subnet.eks_subnet_public_1a.id,
    aws_subnet.eks_subnet_public_1b.id
  ]

  # Permitir tráfego de saída para internet
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  egress {
    protocol   = "udp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  # Permitir tráfego HTTPS/SSH de entrada
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Adicione regra para SSH se necessário
  # Em produção, restrinja para apenas IPs específicos
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0" # Recomendado: restringir para IPs específicos
    from_port  = 22
    to_port    = 22
  }

  # Tráfego de retorno
  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "udp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = format("%s-public-nacl", var.cluster_name)
  }
}

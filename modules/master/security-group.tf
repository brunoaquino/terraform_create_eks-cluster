resource "aws_security_group" "cluster_master_sg" {

  name   = format("%s-master-sg", var.cluster_name)
  vpc_id = var.cluster_vpc.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Permitir HTTPS para fora"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Permitir HTTP para fora"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Permitir DNS TCP para fora"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Permitir DNS UDP para fora"
  }

  tags = {
    Name = format("%s-master-sg", var.cluster_name)
  }

}

resource "aws_security_group_rule" "eks_sg_ingress_rule" {
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  description = "Acesso a API Kubernetes"

  security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  type              = "ingress"
}

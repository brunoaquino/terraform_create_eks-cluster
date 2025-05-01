# Este arquivo contém as configurações específicas para recursos principais, se necessário
# O bloco terraform foi movido para provider.tf

# Variáveis locais para o projeto
locals {
  # Definições gerais do projeto
  cluster_name = var.cluster_name
  aws_region   = var.aws_region
  vpc_cidr     = var.vpc_cidr
  environment  = var.environment
  k8s_version  = var.k8s_version
  base_domain  = var.base_domain

  # Tags padrão para todos os recursos
  default_tags = {
    Environment = var.environment
    Project     = var.cluster_name
    ManagedBy   = "terraform"
  }
}

# Recurso para garantir que o provider kubernetes seja configurado após a criação do cluster
resource "null_resource" "eks_ready" {
  depends_on = [
    module.master,
    module.node
  ]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.master.cluster_name} --region ${var.aws_region}"
  }
}


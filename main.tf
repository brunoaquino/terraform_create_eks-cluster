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


# Configurações básicas
aws_region   = "us-east-1"
environment  = "dev"
cluster_name = "app-cluster"
base_domain  = "mixnarede.com.br"

# VPC e Zonas de Disponibilidade
vpc_cidr = "10.0.0.0/16"

# Zonas de disponibilidade e subnets
availability_zones = ["us-east-1a", "us-east-1b"]
private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
database_subnets   = ["10.0.201.0/24", "10.0.202.0/24"]

# EKS
nodes_instances_sizes = ["t3.large"]
auto_scale_options = {
  min     = 2
  max     = 3
  desired = 2
}

# Versão do Kubernetes
k8s_version = "1.30"

# Configurações de Auto Scaling para CPU
auto_scale_cpu = {
  scale_up_threshold  = 80
  scale_up_period     = 60
  scale_up_evaluation = 2
  scale_up_cooldown   = 300
  scale_up_add        = 1

  scale_down_threshold  = 40
  scale_down_period     = 120
  scale_down_evaluation = 2
  scale_down_cooldown   = 300
  scale_down_remove     = -1
}

# Configurações de Auto Scaling para Memória
auto_scale_memory = {
  scale_up_threshold  = 80
  scale_up_period     = 60
  scale_up_evaluation = 2
  scale_up_cooldown   = 300
  scale_up_add        = 1

  scale_down_threshold  = 40
  scale_down_period     = 120
  scale_down_evaluation = 2
  scale_down_cooldown   = 300
  scale_down_remove     = -1
}

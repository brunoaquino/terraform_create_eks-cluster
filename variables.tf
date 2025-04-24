variable "cluster_name" {
  default = "k8s-demo"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "environment" {
  default     = "dev"
  description = "Ambiente de implantação (dev, staging, prod)"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR da VPC principal"
}

variable "single_az_mode" {
  default     = false
  description = "Modo de zona única para economia de custos"
}

variable "preferred_az" {
  default     = "us-east-1a"
  description = "Zona de disponibilidade preferida quando em modo de zona única"
}

variable "availability_zones" {
  default     = ["us-east-1a", "us-east-1b"]
  description = "Zonas de disponibilidade a serem utilizadas"
}

variable "private_subnets" {
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "CIDRs para subnets privadas"
}

variable "public_subnets" {
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
  description = "CIDRs para subnets públicas"
}

variable "database_subnets" {
  default     = ["10.0.201.0/24", "10.0.202.0/24"]
  description = "CIDRs para subnets de banco de dados"
}

variable "k8s_version" {
  default = "1.30"
}

variable "nodes_instances_sizes" {
  default = [
    //"m6i.xlarge" //recomendação do camunda
    "t3.large"
  ]
}

variable "auto_scale_options" {
  default = {
    min     = 2
    max     = 10
    desired = 4
  }
}

variable "auto_scale_cpu" {
  default = {
    scale_up_threshold  = 80
    scale_up_period     = 60
    scale_up_evaluation = 2
    scale_up_cooldown   = 300
    scale_up_add        = 2

    scale_down_threshold  = 40
    scale_down_period     = 120
    scale_down_evaluation = 2
    scale_down_cooldown   = 300
    scale_down_remove     = -1
  }
}

variable "auto_scale_memory" {
  default = {
    scale_up_threshold  = 80
    scale_up_period     = 60
    scale_up_evaluation = 2
    scale_up_cooldown   = 300
    scale_up_add        = 2

    scale_down_threshold  = 40
    scale_down_period     = 120
    scale_down_evaluation = 2
    scale_down_cooldown   = 300
    scale_down_remove     = -1
  }
  description = "Configurações de auto scaling baseado em memória"
}

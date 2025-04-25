variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "region" {
  description = "Região AWS onde o cluster será criado"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
}

variable "availability_zones" {
  description = "Zonas de disponibilidade para os recursos"
  type        = list(string)
}

variable "private_subnets" {
  description = "Lista de CIDRs para subnets privadas"
  type        = list(string)
}

variable "public_subnets" {
  description = "Lista de CIDRs para subnets públicas"
  type        = list(string)
}

variable "database_subnets" {
  description = "Lista de CIDRs para subnets de banco de dados"
  type        = list(string)
}

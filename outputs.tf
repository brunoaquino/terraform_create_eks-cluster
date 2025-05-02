output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.master.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = module.master.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificado de autoridade do cluster EKS"
  value       = module.master.cluster_certificate_authority_data
  sensitive   = true
}

output "vpc_id" {
  description = "ID da VPC utilizada pelo cluster"
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = module.network.private_subnets
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = module.network.public_subnets
}

output "eks_oidc_issuer_url" {
  description = "URL do emissor OIDC do EKS"
  value       = module.master.oidc_provider_url
}

output "node_group_id" {
  description = "ID do grupo de nós EKS"
  value       = module.node.node_group_id
}

output "node_group_arn" {
  description = "ARN do grupo de nós EKS"
  value       = module.node.node_group_arn
}

output "node_group_status" {
  description = "Status do grupo de nós EKS"
  value       = module.node.node_group_status
}

output "node_role_arn" {
  description = "ARN da função IAM utilizada pelos nós"
  value       = module.node.node_role_arn
}

# Outputs relacionados ao RDS
output "rds_security_group_id" {
  description = "ID do security group para RDS"
  value       = module.network.rds_security_group_id
}

output "db_subnet_group_name" {
  description = "Nome do grupo de subnets para RDS"
  value       = module.network.db_subnet_group_name
}

output "database_subnet_ids" {
  description = "IDs das subnets para banco de dados"
  value       = module.network.database_subnet_ids
}

output "msk_access_role_arn" {
  description = "ARN da função IAM para acesso ao MSK"
  value       = module.master.msk_access_role_arn
}

output "cluster_id" {
  value = aws_eks_cluster.eks_cluster.id
}

output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "oidc_provider_url" {
  value = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

output "eks_cluster" {
  value = aws_eks_cluster.eks_cluster
}

output "security_group" {
  value = aws_security_group.cluster_master_sg
}

output "cert_manager_role_arn" {
  value       = aws_iam_role.cert_manager.arn
  description = "ARN do papel IAM para o cert-manager"
}

output "external_dns_role_arn" {
  value       = aws_iam_role.external_dns.arn
  description = "ARN do papel IAM para o external-dns"
}

output "msk_access_role_arn" {
  description = "ARN da função IAM para acesso ao MSK"
  value       = aws_iam_role.msk_access.arn
}

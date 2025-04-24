output "cluster_id" {
  value = aws_eks_cluster.eks_cluster.id
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

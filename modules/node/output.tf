output "node_group_id" {
  description = "ID do grupo de nós EKS"
  value       = aws_eks_node_group.cluster.id
}

output "node_group_arn" {
  description = "ARN do grupo de nós EKS"
  value       = aws_eks_node_group.cluster.arn
}

output "node_group_status" {
  description = "Status do grupo de nós EKS"
  value       = aws_eks_node_group.cluster.status
}

output "node_group_resources" {
  description = "Recursos associados ao grupo de nós EKS"
  value       = aws_eks_node_group.cluster.resources
}

output "node_group_scaling_config" {
  description = "Configuração de escalonamento do grupo de nós"
  value       = aws_eks_node_group.cluster.scaling_config
}

output "node_role_arn" {
  description = "ARN da função IAM utilizada pelos nós"
  value       = aws_iam_role.eks_node_role.arn
}

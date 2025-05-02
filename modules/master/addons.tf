# Data source para obter as versões disponíveis do addon ADOT
data "aws_eks_addon_version" "adot" {
  addon_name         = "adot"
  kubernetes_version = aws_eks_cluster.eks_cluster.version
  most_recent        = true
}

# AWS Distro for OpenTelemetry (ADOT) Addon
resource "aws_eks_addon" "adot" {
  cluster_name      = aws_eks_cluster.eks_cluster.name
  addon_name        = "adot"
  addon_version     = data.aws_eks_addon_version.adot.version
  resolve_conflicts = "OVERWRITE"

  # Dependência explícita do cluster EKS
  depends_on = [
    aws_eks_cluster.eks_cluster
  ]

  tags = {
    "eks_addon" = "adot"
  }
}

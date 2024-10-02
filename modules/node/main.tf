resource "aws_launch_template" "aws_launch_template" {
  metadata_options {
    http_tokens                 = "required" # Exige IMDSv2
    http_endpoint               = "enabled"  # Habilita IMDS
    http_put_response_hop_limit = 2          # Limita hops para maior segurança
  }
}
resource "aws_eks_node_group" "eks_node_group" {

  cluster_name    = var.cluster_name
  node_group_name = format("%s-node-group", var.cluster_name)
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    var.private_subnet_1a,
    var.private_subnet_1b
  ]

  instance_types = var.nodes_instances_sizes

  scaling_config {
    desired_size = lookup(var.auto_scale_options, "desired")
    max_size     = lookup(var.auto_scale_options, "max")
    min_size     = lookup(var.auto_scale_options, "min")
  }

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_AmazonEC2ContainerRegistryReadOnly
  ]

  launch_template {
    id      = aws_launch_template.aws_launch_template.id
    version = "$Latest"
  }

}

data "aws_eks_addon_version" "this" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = var.k8s_version
  most_recent        = true
}

resource "aws_eks_addon" "this" {

  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"

  addon_version               = data.aws_eks_addon_version.this.version
  configuration_values        = null
  preserve                    = true
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = null

  depends_on = [
    aws_eks_node_group.eks_node_group
  ]

}

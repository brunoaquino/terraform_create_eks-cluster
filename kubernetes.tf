# Service Account para acesso ao MSK
resource "kubernetes_service_account" "msk_access" {
  metadata {
    name      = "msk-access-sa"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.master.msk_access_role_arn
    }
  }

  # Dependência explícita do cluster EKS
  depends_on = [
    module.master,
    null_resource.eks_ready
  ]
}

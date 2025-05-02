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

# Data source para obter o namespace do ADOT criado pelo addon
data "kubernetes_namespace" "adot" {
  metadata {
    name = "opentelemetry-operator-system"
  }

  depends_on = [
    module.master.adot_addon,
    null_resource.eks_ready
  ]
}

# Data source para obter o service account do ADOT criado pelo addon
data "kubernetes_service_account" "adot" {
  metadata {
    name      = "opentelemetry-operator"
    namespace = data.kubernetes_namespace.adot.metadata[0].name
  }

  depends_on = [
    data.kubernetes_namespace.adot
  ]
}

# Atualizar o service account existente com a anotação para IAM role
resource "kubernetes_annotations" "adot_service_account" {
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = data.kubernetes_service_account.adot.metadata[0].name
    namespace = data.kubernetes_service_account.adot.metadata[0].namespace
  }
  annotations = {
    "eks.amazonaws.com/role-arn" = module.master.adot_role_arn
  }

  depends_on = [
    data.kubernetes_service_account.adot
  ]
}

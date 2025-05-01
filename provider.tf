provider "aws" {
  region = var.aws_region
}

# Definição dos providers necessários
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Não precisamos mais dos providers kubernetes/helm/kubectl por enquanto

provider "kubernetes" {
  host                   = module.master.cluster_endpoint
  cluster_ca_certificate = base64decode(module.master.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.master.cluster_name
    ]
  }
}

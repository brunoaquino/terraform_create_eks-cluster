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

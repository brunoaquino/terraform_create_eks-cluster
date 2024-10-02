resource "aws_eks_cluster" "eks_cluster" {

  name     = var.cluster_name
  role_arn = aws_iam_role.eks_master_role.arn
  version  = var.k8s_version

  vpc_config {

    security_group_ids = [
      aws_security_group.cluster_master_sg.id
    ]

    subnet_ids = [
      var.private_subnet_1a,
      var.private_subnet_1b
    ]

  }

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_cluster,
    aws_iam_role_policy_attachment.eks_cluster_service
  ]

}

resource "aws_ecr_repository" "ecr_repository" {
  name = "my-ecr-repository"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"
}


resource "aws_ecr_lifecycle_policy" "policy" {
  repository = aws_ecr_repository.ecr_repository.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 30 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 30
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}


data "aws_iam_policy_document" "eks_ecr_access_policy" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "eks_ecr_policy" {
  name   = "eks-ecr-access-policy"
  role   = aws_iam_role.eks_master_role.name
  policy = data.aws_iam_policy_document.eks_ecr_access_policy.json
}

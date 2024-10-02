output "cluster_vpc" {
  value = aws_vpc.eks_vpc
}

output "private_subnet_1a" {
  value = aws_subnet.eks_subnet_private_1a.id
}

output "private_subnet_1b" {
  value = aws_subnet.eks_subnet_private_1b.id
}

output "public_subnet_1a" {
  value = aws_subnet.eks_subnet_public_1a.id
}

output "public_subnet_1b" {
  value = aws_subnet.eks_subnet_public_1b.id
}
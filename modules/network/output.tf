output "cluster_vpc" {
  value = aws_vpc.eks_vpc
}

output "vpc_id" {
  value = aws_vpc.eks_vpc.id
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

output "database_subnet_1a" {
  value = aws_subnet.eks_subnet_database_1a.id
}

output "database_subnet_1b" {
  value = aws_subnet.eks_subnet_database_1b.id
}

output "private_subnets" {
  value = [
    aws_subnet.eks_subnet_private_1a.id,
    aws_subnet.eks_subnet_private_1b.id
  ]
}

output "public_subnets" {
  value = [
    aws_subnet.eks_subnet_public_1a.id,
    aws_subnet.eks_subnet_public_1b.id
  ]
}

output "database_subnets" {
  value = [
    aws_subnet.eks_subnet_database_1a.id,
    aws_subnet.eks_subnet_database_1b.id
  ]
}

output "private_route_table" {
  value = aws_route_table.eks_nat_rt.id
}

output "public_route_table" {
  value = aws_route_table.eks_public_rt.id
}

output "database_route_table" {
  value = aws_route_table.eks_database_rt.id
}

output "route_tables" {
  value = {
    private  = aws_route_table.eks_nat_rt.id
    public   = aws_route_table.eks_public_rt.id
    database = aws_route_table.eks_database_rt.id
  }
}

# Outputs para RDS
output "rds_security_group_id" {
  description = "ID do security group para RDS"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "Nome do grupo de subnets para RDS"
  value       = aws_db_subnet_group.database.name
}

output "database_subnet_ids" {
  description = "IDs das subnets de banco de dados"
  value = [
    aws_subnet.eks_subnet_database_1a.id,
    aws_subnet.eks_subnet_database_1b.id
  ]
}

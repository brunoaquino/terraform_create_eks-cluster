module "network" {
  source = "./modules/network"

  cluster_name       = var.cluster_name
  region             = var.aws_region
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  database_subnets   = var.database_subnets
}

module "master" {
  source = "./modules/master"

  cluster_name      = var.cluster_name
  aws_region        = var.aws_region
  k8s_version       = var.k8s_version
  cluster_vpc       = module.network.cluster_vpc.id
  private_subnet_1a = module.network.private_subnet_1a
  private_subnet_1b = module.network.private_subnet_1b

  depends_on = [module.network]
}

module "node" {
  source = "./modules/node"

  cluster_name          = var.cluster_name
  aws_region            = var.aws_region
  k8s_version           = var.k8s_version
  cluster_vpc           = module.network.cluster_vpc.id
  private_subnet_1a     = module.network.private_subnet_1a
  private_subnet_1b     = module.network.private_subnet_1b
  nodes_instances_sizes = var.nodes_instances_sizes
  auto_scale_options    = var.auto_scale_options
  auto_scale_cpu        = var.auto_scale_cpu
  auto_scale_memory     = var.auto_scale_memory
  eks_cluster           = module.master.cluster_id
  eks_cluster_sg        = module.master.security_group.id

  depends_on = [module.master]
}

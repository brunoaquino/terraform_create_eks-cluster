variable "aws_region" {}

variable "cluster_name" {}

variable "k8s_version" {}

variable "cluster_vpc" {}

variable "private_subnet_1a" {}

variable "private_subnet_1b" {}

variable "eks_cluster" {}

variable "eks_cluster_sg" {}

variable "nodes_instances_sizes" {
  type = list(string)
}

variable "auto_scale_options" {
  type = map(number)
}

variable "auto_scale_cpu" {}

variable "auto_scale_memory" {}

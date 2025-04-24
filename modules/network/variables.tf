variable "cluster_name" {}

variable "region" {}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "database_subnets" {
  default = ["10.0.201.0/24", "10.0.202.0/24"]
}

variable "single_az_mode" {
  default = false
}

variable "preferred_az" {
  default = "us-east-1a"
}

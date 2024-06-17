##############
# VPC Variables
###############
name        = "EKS-VPC"
cidr            = "10.0.0.0/16"
region          = "us-east-1"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
enable_nat_gateway   = true
single_nat_gateway   = true
enable_dns_hostnames = true
enable_dns_support   = true
tags = {
  Terraform   = "true"
  Environment = "dev"
}

################
# EKS variables
################
cluster_name                    = "dev-eks"
cluster_version                 = "1.29"
cluster_endpoint_private_access = true
cluster_endpoint_public_access  = true
cluster_addons = {
  coredns = {
    most_recent                 = true
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE"
  }
  kube-proxy = {
    most_recent = true
  }
  vpc-cni = {
    most_recent = true
  }
}


eks_managed_node_groups = {

  test = {
    desired_size = 1
    min_size     = 1
    max_size     = 10
    
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
  }
}
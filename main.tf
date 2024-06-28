
data "aws_availability_zones" "azs" {}

data "aws_secretsmanager_secret_version" "creds" {
  secret_id = "db-creds-v2"
}

locals {
  db_creds = jsondecode(
  data.aws_secretsmanager_secret_version.creds.secret_string)
}

# VPC for Cluster
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name                         = var.name
  cidr                         = var.cidr
  azs                          = ["${var.region}a", "${var.region}b"]
  private_subnets              = var.private_subnets
  public_subnets               = var.public_subnets
  create_database_subnet_group = var.create_database_subnet_group
  database_subnets             = var.database_subnets
  database_subnet_group_name   = var.database_subnet_group_name
  enable_nat_gateway           = var.enable_nat_gateway
  single_nat_gateway           = var.single_nat_gateway
  enable_dns_hostnames         = var.enable_dns_hostnames
  enable_dns_support           = var.enable_dns_support

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = var.tags
}

module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "~> 19.16"
  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  cluster_addons                  = var.cluster_addons
  eks_managed_node_groups         = var.eks_managed_node_groups
  tags                            = var.tags
}

module "rds" {
  source                 = "terraform-aws-modules/rds/aws"
  version                = "6.7.0"
  identifier             = var.identifier
  create_db_instance     = var.create_db_instance
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  db_subnet_group_name   = var.database_subnet_group_name
  subnet_ids             = module.vpc.database_subnets
  allocated_storage      = var.allocated_storage
  vpc_security_group_ids = [module.sg-rds.security_group_id]
  db_name                = var.db_name
  username               = local.db_creds.username
  password               = local.db_creds.password
  port                   = var.port
  family                 = var.family
  major_engine_version   = var.major_engine_version
  deletion_protection    = var.deletion_protection
  tags                   = var.tags
}

module "sg-rds" {
  source                   = "terraform-aws-modules/security-group/aws"
  version                  = "5.1.2"
  name                     = var.sg-name
  vpc_id                   = module.vpc.vpc_id
  create                   = var.create
  ingress_cidr_blocks      = var.ingress_cidr_blocks
  ingress_rules            = var.ingress_rules
  ingress_with_cidr_blocks = var.ingress_with_cidr_blocks
  egress_with_cidr_blocks  = var.egress_with_cidr_blocks
  egress_cidr_blocks       = var.egress_cidr_blocks
  egress_rules             = var.egress_rules
}
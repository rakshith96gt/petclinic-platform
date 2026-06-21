module "vpc" {
  source = "../../modules/vpc"

  project             = "petclinic"
  environment         = "dev"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  availability_zones  = ["ap-south-2a", "ap-south-2b"]

  tags = {
    Component = "networking"
  }
}

data "aws_caller_identity" "current" {}

module "eks" {
  source = "../../modules/eks"

  project     = "petclinic"
  environment = "dev"
  subnet_ids  = module.vpc.public_subnet_ids
  cluster_sg_id = module.vpc.eks_cluster_sg_id
  node_sg_id    = module.vpc.eks_node_sg_id
  deployer_arn  = data.aws_caller_identity.current.arn

  tags = {
    Component = "compute"
  }
}

module "ecr" {
  source = "../../modules/ecr"

  project       = "petclinic"
  environment   = "dev"
  service_names = [
    "config-server",
    "discovery-server",
    "api-gateway",
    "customers-service",
    "visits-service",
    "vets-service",
    "genai-service",
    "admin-server"
  ]

  tags = {
    Component = "container-registry"
  }
}

module "rds" {
  source = "../../modules/rds"

  project           = "petclinic"
  environment      = "dev"
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id  = module.vpc.rds_sg_id
  instance_class    = "db.t4g.micro"
  multi_az          = false
  skip_final_snapshot = true
  backup_retention_period = 7

  tags = {
    Component = "database"
  }
}

module "dns" {
  source = "../../modules/dns"

  project      = "petclinic"
  environment  = "dev"
  domain_name  = var.domain_name
  alb_dns_name = var.alb_dns_name
  alb_zone_id  = var.alb_zone_id

  tags = {
    Component = "dns"
  }
}

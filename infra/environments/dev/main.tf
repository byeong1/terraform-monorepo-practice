# Dev 환경 메인 구성 파일

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  region             = var.region
  project_name       = var.project_name
}

module "security" {
  source = "../../modules/security"

  vpc_id       = module.vpc.vpc_id
  my_ip        = var.my_ip
  project_name = var.project_name
}

module "rds" {
  source = "../../modules/rds"

  project_name      = var.project_name
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security.db_security_group_id
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
}

module "ec2" {
  source = "../../modules/ec2"

  ami_id            = var.ami_id
  instance_type     = var.instance_type
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.security.security_group_id
  project_name      = var.project_name
  db_password       = var.db_password
  db_host           = module.rds.db_hostname
  db_username       = var.db_username
  db_name           = var.db_name
}

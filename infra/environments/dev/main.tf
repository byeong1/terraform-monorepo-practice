# Dev 환경 메인 구성 파일

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-practice-bbi-tfstate"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-practice-bbi-tflock"
    encrypt        = true
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

module "media" {
  source = "../../modules/media"

  project_name = var.project_name
  region       = var.region
}

module "lambda" {
  source = "../../modules/lambda"

  project_name          = var.project_name
  region                = var.region
  media_bucket_name     = module.media.bucket_name
  media_bucket_arn      = module.media.bucket_arn
  mediaconvert_role_arn = module.media.mediaconvert_role_arn
  callback_url          = "http://${module.ec2.instance_public_ip}/api/videos/callback"
  callback_secret       = var.callback_secret
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  region       = var.region
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
  public_key        = file(var.public_key_path)
  media_bucket_name = module.media.bucket_name
  cloudfront_domain = module.media.cloudfront_domain
  region            = var.region
  callback_secret   = var.callback_secret
  backend_image     = module.ecr.backend_repository_url
  frontend_image    = module.ecr.frontend_repository_url
}

resource "null_resource" "deploy" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "${path.module}/../../scripts/deploy.sh ${var.region} ${module.ecr.backend_repository_url} ${module.ecr.frontend_repository_url} ${path.module}/../../../app ${module.ec2.instance_public_ip} ${var.private_key_path}"
    interpreter = ["C:/Program Files/Git/bin/bash.exe", "-c"]
  }

  depends_on = [
    module.ecr,
    module.ec2
  ]
}

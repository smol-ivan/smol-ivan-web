terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "network" {
  source = "./network"

  project_name = var.project_name
}

module "iam" {
  source = "./iam"

  project_name = var.project_name
}

module "ecr" {
  source = "./ecr"

  repository_name = "${var.project_name}-web"
}

module "compute" {
  source = "./compute"

  project_name           = var.project_name
  key_name               = var.key_name
  security_group_id      = module.network.security_group_id
  instance_profile_name  = module.iam.instance_profile_name
  swap_size_gb           = var.swap_size_gb
  ami_id                 = var.ami_id
}

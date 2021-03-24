terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.10"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  zones = ["a", "b", "c"]
  azs   = [for z in local.zones : "${var.region}${z}"]
}

module "subnet_addrs" {
  source          = "hashicorp/subnets/cidr"
  base_cidr_block = var.cidr
  networks = flatten([
    for n in [["public", 2], ["intra", 4], ["db", 6]] : [
      for z in local.zones : {
        name     = "${n[0]}-${z}"
        new_bits = n[1]
      }
    ]
  ])
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = ">= 2.77.0"
  name   = var.name
  cidr   = var.cidr
  azs    = local.azs
  public_subnets = [
    for z in local.zones : module.subnet_addrs.network_cidr_blocks["public-${z}"]
  ]
  public_subnet_tags = { Kind = "public" }
  intra_subnets = [
    for z in local.zones : module.subnet_addrs.network_cidr_blocks["intra-${z}"]
  ]
  intra_subnet_tags = { Kind = "intra" }
  database_subnets = [
    for z in local.zones : module.subnet_addrs.network_cidr_blocks["db-${z}"]
  ]
  database_subnet_tags = { Kind = "database" }
  enable_s3_endpoint   = true
  tags = {
    Name = var.name
  }
}

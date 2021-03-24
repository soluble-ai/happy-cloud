locals {
  key_pair_public_key = var.key_pair_public_key != "" ? var.key_pair_public_key : file("~/.ssh/id_rsa.pub")
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  key_name   = var.name
  public_key = local.key_pair_public_key
  create_key_pair = var.create_key_pair
}
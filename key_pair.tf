resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  count = var.create_key_pair ? 1 : 0
}

# save ssh key in ssm parameter
resource "aws_ssm_parameter" "key_pair" {
  count = var.create_key_pair ? 1 : 0
  name = "/vpc/${var.name}/key_pair"
  type = "SecureString"
  value = tls_private_key.key_pair[0].private_key_pem
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  version = "~> 0.6.0"
  key_name   = var.name
  public_key = tls_private_key.key_pair[0].public_key_openssh
  create_key_pair = var.create_key_pair
}

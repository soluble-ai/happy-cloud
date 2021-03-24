module "public_load_balancer_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "public_load_balancer"
  vpc_id = module.vpc.vpc_id
  ingress_cidr_blocks = [ "0.0.0.0/0" ]
  egress_cidr_blocks = [ "0.0.0.0/0" ]
  egress_rules = [ "all-all" ]
  ingress_rules = [ "http-80-tcp", "https-443-tcp" ]
}

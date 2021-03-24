module "public_instance_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  name                = "${var.name}-public_instance"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["all-icmp"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_ipv6_cidr_blocks = []
  egress_rules        = ["all-all"]
  ingress_with_source_security_group_id = [
    {
      rule: "http-8080-tcp"
      source_security_group_id : module.public_load_balancer_sg.this_security_group_id
    },
    {
      rule: "https-8443-tcp"
      source_security_group_id : module.public_load_balancer_sg.this_security_group_id
    }
  ]
}

module "public_instance_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 3.0"

  trusted_role_services = [ "ec2.amazonaws.com" ]

  create_role = true
  create_instance_profile = true
  role_requires_mfa = false
  attach_readonly_policy = true
  role_name         = "${var.name}-public_instance"
}

module "public_fleet" {
  source = "./spot-fleet"
  name = "${var.name}-public"
  subnet_ids = module.vpc.public_subnets
  target_capacity = 2
  instance_types = [ "t3a.small" ]
  key_name = module.key_pair.this_key_pair_key_name
  user_data = <<EOF
#!/bin/bash
sudo yum install ec2-instance-connect
EOF
  security_group_ids = [ 
    module.jump_access_sg.this_security_group_id,
    module.public_instance_sg.this_security_group_id 
  ]
  instance_profile_arn = module.public_instance_role.this_iam_instance_profile_arn
}
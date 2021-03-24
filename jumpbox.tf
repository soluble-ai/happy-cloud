module "jumpbox_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  name                = "${var.name}-jumpbox"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
  egress_ipv6_cidr_blocks = []
}

module "jump_access_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  name                = "${var.name}-jumpbox_access"
  vpc_id              = module.vpc.vpc_id
  ingress_with_source_security_group_id = [
    {
      rule : "ssh-tcp"
      source_security_group_id : module.jumpbox_sg.this_security_group_id
    }
  ]
}

module "jumpbox_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 3.0"

  trusted_role_services = [ "ec2.amazonaws.com" ]
  custom_role_policy_arns = [ 
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    aws_iam_policy.jumpbox_ec2_connect.arn
  ]
  create_role = true
  create_instance_profile = true
  role_requires_mfa = false
  attach_readonly_policy = true
  role_name         = "${var.name}-jumpbox"
}

module "jumpbox_fleet" {
  count = 1
  source = "./spot-fleet"
  name = "${var.name}-jumpbox"
  subnet_ids = [ module.vpc.public_subnets[0] ]
  target_capacity = 1
  instance_types = [ "t3a.small" ]
  key_name = module.key_pair.this_key_pair_key_name
  user_data = <<EOF
sudo yum install -y python3
sudo python3 -m pip install -U pip
pip install --user ec2instanceconnectcli
EOF  
  security_group_ids = [ module.jumpbox_sg.this_security_group_id ]
  instance_profile_arn = module.jumpbox_role.this_iam_instance_profile_arn
}

resource "aws_iam_policy" "jumpbox_ec2_connect" {
  name        = "${var.name}-jumpbox-ec2-connect"
  description = "Allow EC2 Connect"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "ec2-instance-connect:SendSSHPublicKey",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": "ec2:DescribeInstances",
        "Resource": "*"
      }
    ]
}  
EOF  
}

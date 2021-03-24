data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_ami" "amazon-linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "launch_template" {
  name                     = var.name
  update_default_version = true
  image_id                 = data.aws_ami.amazon-linux.id
  vpc_security_group_ids   = var.security_group_ids
  key_name                 = var.key_name
  iam_instance_profile {
    arn = var.instance_profile_arn
  }
  tags = {
    Name = var.name
  }
  dynamic "tag_specifications" {
    for_each = [ "instance", "volume" ]
    iterator = type
    content {
      resource_type = type.value
      tags = {
        Name = var.name
      }
    }
  }
  user_data = base64encode(var.user_data)
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      encrypted   = true
      volume_size = var.root_size
      volume_type = "gp2"
    }
  }
}

resource "aws_spot_fleet_request" "linux" {
  iam_fleet_role                      = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-ec2-spot-fleet-tagging-role"
  target_capacity                     = var.target_capacity
  allocation_strategy                 = "lowestPrice"
  terminate_instances_with_expiration = true
  lifecycle {
    ignore_changes = [valid_until, target_capacity]
  }
  target_group_arns = var.target_group_arns
  launch_template_config {
      launch_template_specification {
        id      = aws_launch_template.launch_template.id
        version = aws_launch_template.launch_template.latest_version
      }
      dynamic "overrides" {
        for_each = flatten([for s in var.subnet_ids :
          [for t in var.instance_types : {
            subnet_id: s
            instance_type: t 
          }]])
        iterator = st
        content {
          subnet_id = st.value.subnet_id
          instance_type = st.value.instance_type
        }
      }
  }
  tags = {
    Name = var.name
  }
}

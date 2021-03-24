module "db_access_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "db_access"
  vpc_id = module.vpc.vpc_id
}

module "db" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 3.0"
  name = var.name
  engine_mode = "serverless"
  engine = "aurora-postgresql"
  engine_version = null
  subnets = module.vpc.database_subnets
  vpc_id = module.vpc.vpc_id
  skip_final_snapshot = true
  apply_immediately   = true
  storage_encrypted   = true
  allowed_security_groups = [ module.db_access_sg.this_security_group_id ]
  db_subnet_group_name = module.vpc.database_subnet_group_name 
  replica_count = 0
  scaling_configuration = {
    min_capacity: 2,
    max_capacity: 4
  }
}

resource "aws_ssm_parameter" "db_master_password" {
  name = "/aurora/${var.name}/master_password"
  description = "Master password for aurora db ${var.name}"
  type = "SecureString"
  value = module.db.this_rds_cluster_master_password
}
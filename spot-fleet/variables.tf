variable "name" {}
variable "subnet_ids" {}
variable "target_capacity" {}
variable "instance_types" {
  type = list
}
variable "key_name" {}
variable "user_data" {
  default = ""
}
variable "target_group_arns" {
  type    = list
  default = []
}
variable "security_group_ids" {
  type = list
}
variable "instance_profile_arn" {}
variable "root_size" {
  default = 8
}
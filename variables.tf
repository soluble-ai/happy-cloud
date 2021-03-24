variable "name" {
  default = "happy-cloud"
}

variable "cidr" {
  default = "10.28.0.0/20"
}

variable "region" {
  default = "us-east-2"
}

variable "create_key_pair" {
  default = true
}

variable "key_pair_public_key" {
  default = ""
}
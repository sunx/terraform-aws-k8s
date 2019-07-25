
variable "COUNTRY" {
  default = "GB"
}
variable "LOCALITY" {
  default = "London"
}
variable "OU" {
  default = "k8s"
}
variable "aws-region" {
  default = "eu-central-1"
  description = "Frankfurt Amazon region"
}
variable "aws-profile" {
  default = "default"
}
variable "aws-key-name" {
  default = "ksuser"
  description = "EC2 acces key pair"
}
variable "aws_type" {
  default = "t2.micro"
}
variable "nodes_count" {
  default = "2"
}
variable "masters_count" {
  default = "3"
}
variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "aws_amis" {
  default = "ami-009c174642dba28e4"
}
variable "secure-port" {
  default = "6443"
}
variable "secure_protocol" {
  default = "TCP"
}
variable "elb_proto" {
  default = "SSL"
}
variable "my_ing_proto" {
  default = "TCP"
}
variable "DOMAIN" {
  default = "cluster.local"
}
variable "KSSUBNET" {
  default = "10.244.0.0/16"
}
variable "vpc-block" {
  default = "10.0.0.0/16"
}
variable "subnet-block" {
  default = "10.0.1.0/24"
}

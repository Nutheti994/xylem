variable "region" {
  description = "Region for this VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public-subnet-cidr_block" {
  description = "CIDR fo public subnet"
  type        = string
}

variable "ami" {
  description = "AMI of the Image"
  type        = string
}

variable "instance_type" {
  description = "Type of the instance"
  type        = string
}

variable "security_group" {
  description = "Security group for perticular instance"
}
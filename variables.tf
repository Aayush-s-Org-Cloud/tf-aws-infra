variable "aws_profile" {
  description = "Profile to be used for AWS CLI"
  type        = string
}

variable "aws_region" {
  description = "Resources to be deployed in AWS regions"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of zones available"
  type        = list(string)
}
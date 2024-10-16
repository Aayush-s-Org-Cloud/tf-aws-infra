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

variable "custom_ami_id" {
  description = "ID of the custom AMI built with Packer"
  type        = string
}

variable "application_port" {
  description = "Port on which the application runs"
  type        = number
  default     = 8080
}

variable "key_pair_name" {
  description = "SSH Key Pair name for EC2 access"
  type        = string
}
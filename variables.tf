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
}

variable "key_pair_name" {
  description = "SSH Key Pair name for EC2 access"
  type        = string
}

# Variables for database configuration
variable "db_port" {
  description = "Database port (3306 for MySQL/MariaDB, 5432 for PostgreSQL)"
  type        = number
  default     = 3306 # MySQL default, adjust for PostgreSQL
}

variable "db_password" {
  description = "Master password for the RDS instance"
  type        = string
}

variable "db_user" {
  description = "The username for the RDS database"
  type        = string
}

variable "db_dialect" {
  description = "The database dialect (e.g., mysql, postgres)"
  type        = string
}
variable "db_name" {
  description = "The name of the database"
  type        = string
}
variable "route53_zone_id" {
  description = "The Route 53 Hosted Zone ID for your domain."
  type        = string
}

variable "domain_name" {
  description = "The root domain name (e.g., example.com)."
  type        = string
}

# variables.tf

variable "lambda_function_name" {
  description = "The name of the Lambda function for email verification."
  type        = string
  default     = "email-verification-lambda"
}

variable "sendgrid_api_key" {
  description = "API key for SendGrid"
  type        = string
  sensitive   = true
}

variable "base_url" {
  description = "Base URL for the application"
  type        = string
}

variable "email_verification_zip_path" {
  description = "Path to the email verification zip file"
  type        = string
}
  
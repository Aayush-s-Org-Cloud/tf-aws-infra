provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region

}

# data.tf

data "aws_caller_identity" "current" {}
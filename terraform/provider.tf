provider "aws" {
  region  = "us-east-2"
  profile = "default"

  default_tags {
    tags = {
      created_by        = "terraform"
      repository        = "https://github.com/ralphcarlisle/devops-code-challenge.git"
      support_level     = "testing"
      terraform_version = "1.7.4"
    }
  }
}

terraform {
  required_version = ">= 1.7.2"
  backend "s3" {
    bucket = "lightfeather"
    key    = "state"
    region = "us-east-2"

#  backend "local" {
#    path = "/home/ec2-user/terraform.tfstate"
#  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.39.1"
    }
  }
}
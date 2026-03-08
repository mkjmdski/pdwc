terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  cloud {
    organization = "uam"
    workspaces {
      name = "pdwc"
    }
  }
}

provider "aws" {
  profile      = "default"
  region       = var.region
  default_tags = local.common_tags
}
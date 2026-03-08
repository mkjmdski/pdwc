terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    archive = {
      source = "hashicorp/archive"
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
  profile = "default"
  region  = var.region
  default_tags {
    tags = local.common_tags
  }
}
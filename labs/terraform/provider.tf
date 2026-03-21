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

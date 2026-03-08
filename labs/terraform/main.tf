locals {
  common_tags = {
    purpose = "UAM Cloud Data Processing"
    environment = "DEV"
    owner = var.student_full_name
  }
}

resource "aws_s3_bucket" "bronze" {
  bucket = "pdwc-${var.environment}-bronze"
}

resource "aws_s3_bucket" "silver" {
  bucket = "pdwc-${var.environment}-silver"
}

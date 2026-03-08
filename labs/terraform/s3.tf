resource "aws_s3_bucket" "landings" {
  for_each = toset([
    "raw",
    "processed",
  ])
  bucket        = "datalake-${each.key}-${local.identifier}"
  force_destroy = true
}

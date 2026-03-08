resource "aws_s3_bucket" "landings" {
  for_each = toset([
    "gold",
    "silver",
    "bronze",
  ])
  bucket        = "datalake-${each.key}-${local.identifier}"
  force_destroy = true
}

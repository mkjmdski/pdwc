resource "aws_s3_bucket" "main_dl_bucket" {
  bucket = "datalake-${var.environment}-${var.account_number}-${var.student_initials}-${var.student_index_no}"
  force_destroy = true

  tags = merge(local.common_tags, )
}
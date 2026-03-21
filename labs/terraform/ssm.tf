resource "aws_ssm_parameter" "processed_bucket" {
  name  = "/datalake/${var.student_initials}/${var.student_index_no}/processed_bucket"
  type  = "String"
  value = aws_s3_bucket.landings["processed"].bucket
}
